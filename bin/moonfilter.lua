#!/usr/bin/env lua
-- Moonfilter is a general-purpose text classifier based on OSBF-Lua.
-- Copyright (C) 2007 Christian Siefkes.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
------------------------------------------------------------------------
-- This file defines the moonfilter module, wrapping the osbf module and
-- adding functionality for more comfortable training and classification.
-- Unless explicitly stated otherwise, all methods raise an error in case
-- of an error situation (instead of returning nil + an error message).
------------------------------------------------------------------------
-- v1.0  - 2007-01-18 - Christian Siefkes - Initial version, roughly based
--     on Fidelis Assis' toer.lua script from the OSBF-Lua
--     [http://osbf-lua.luaforge.net/] distribution
-- v1.01 - 2007-10-08 - Christian Siefkes - Fixed 2 bugs:
--     classification of very short texts (< 4 words) failed,
--     moonrunner choked on empty command lines

----- Load required modules + functions and define module --------------

-- Load required modules
local io = io
local math = math
local string = string
local table = table

-- Load required functions
local assert = assert
local error = error
local ipairs = ipairs

local osbf = require "osbf"  -- load osbf module
module(...)                  -- declare module


----- Exported configuration variables ---------------------------------

-- Minimum absolute pR a correct classification must get not to trigger a
-- reinforcement.
threshold = 10
-- Number of buckets in the database. The minimum value recommended for
-- production is 94321.
buckets = 500501
-- Maximum text size, 0 means full document (default). A reasonable value
-- might be 500000 (half a megabyte).
max_text_size = 0
-- Minimum probability ratio over the classes a feature must have not to be
-- ignored. 1 means ignore nothing (default).
min_p_ratio = 1
-- Token delimiters, in addition to whitespace. None by default, could be set
-- e.g. to ".@:/".
delimiters = ".@:/(),"
-- Whether text should be wrapped around (by re-appending the first 4 tokens
-- after the last).
wrap_around = true
-- The directory where class database files are stored. Defaults to the
-- current working directory (empty string). Note that the directory name
-- MUST end in a path separator (typically '/' or '\',
-- depending on your OS) in all other cases. Changing this value will
-- only affect future calls to the |classes| command, it won't change
-- the location of currently active classes.
classdir = "../osbf/"

----- Internal Variables -----------------------------------------------

local class_ext  = ".cfc"   -- extension of class databases (incl. dot)
local class_names = {}      -- the set of classes
local class_indexes = {}    -- map class names to positions in set
local lines = nil           -- the text to classify/train as an array of lines
local text = nil            -- the text to classify/train as a string

-- dbset is the set of single class databases to be used for classification
local dbset = {
    classes    = {},         -- the set of classes, with file extensions
    ncfs       = 1,          -- split "classes" in 2 sublists. "ncfs" is
                             -- the number of classes in the first sublist.
                             -- Currently fixed to 1.
    delimiters = delimiters  -- extra token delimiters, if any
}

-- Flags
local classify_flags            = 0
local learn_flags               = 0

-- For storing result of last classification
local last_classify_result = nil
local last_filename        = nil

---- Internal helper functions -----------------------------------------

-- Returns a string with a statistics report of the database for a given
-- class.
local function dbfile_stats (class)
    dbfile = classdir .. class .. class_ext    -- complete file name
    local OSBF_Bayes_db_version = 5  -- OSBF-Bayes database indentifier
    local report = "-- Statistics for " .. dbfile .. "\n"
    local version = "OSBF-Bayes"
    local stats_lua = osbf.stats(dbfile)

    if (stats_lua.version == OSBF_Bayes_db_version) then
      report = report .. string.format(
        "%-35s%12s\n%-35s%12d\n%-35s%12.1f\n%-35s%12d\n%-35s%12d\n%-35s%12d\n",
        "Database version:", version,
        "Total buckets in database:", stats_lua.buckets,
        "Buckets used (%):", stats_lua.use * 100,
        "Trainings:", stats_lua.learnings,
        "Bucket size (bytes):", stats_lua.bucket_size,
        "Header size (bytes):", stats_lua.header_size)
      report = report .. string.format("%-35s%12d\n%-35s%12d\n%-35s%12d\n\n",
        "Number of chains:", stats_lua.chains,
        "Max chain len (buckets):", stats_lua.max_chain,
        "Average chain length (buckets):", stats_lua.avg_chain,
        "Max bucket displacement:", stats_lua.max_displacement)
    else
        report = report .. string.format("%-35s%12s\n", "Database version:",
            "Unknown")
    end

    return report
end

-- Crops a string to the specified number of bytes. Ensures that the returned
-- string ends at a word boundary by completely deleting a word (sequence of
-- non-whitespace characters) that would otherwise be split. Whitespace at
-- the end of the cropped string is also removed.
--
-- If the length of the string is <= maxbytes or if maxbytes is <= 0, the
-- string is returned without changes.
local function crop(str, maxbytes)
    if maxbytes <= 0 or string.len(str) <= maxbytes then
        return str     -- no need to crop anything
    else
        -- preserve one character more
        local result = string.sub(str, 1, maxbytes)
        -- and delete last (partial) word (if any) + preceding whitespace
        result = string.match(result, "^(.*)%s+%S*$")
        return result
    end
end

-- Reads the contents of a file and returns them as a text string.
-- The special filename "-" means to read from standard input until
-- the end of input.
--
-- If maxbytes is a positive value (> 0), the returned result will be
-- |crop|ped to the specified length.
-- Raises an error if the file can't be read.
local function readfile(filename, maxbytes)
    local file, result
    if filename == "-" then
        file = io.input()
    else
        file = assert(io.open(filename, "r"))
    end

    if maxbytes and (maxbytes > 0) then
        if file == io.input() then -- consume rest of stdin
            result = assert(file:read("*a"))
        else -- just read one character more for correct cropping
            result = assert(file:read(maxbytes + 1))
        end
        -- crop to required length
        result = crop(result, maxbytes)
    else
        result = assert(file:read("*a"))
    end

    if file ~= io.input() then file:close() end
    return result
end

-- Updates the value of the text variable. If filename is not nil or empty,
-- the contents of the file will be used (the special filename "-" denotes
-- from standard input); otherwise the contents of the lines array (populated
-- by the last readuntil command) will be concatenated and used; otherwise (if
-- the lines array is nil), the text won't be changed.
--
-- The text will be limited to max_text_size bytes, if this variable is > 0.
-- It will be wrapped around (by re-appending the first 4 tokens at the end of
-- the text) if the wrap_around variable is true.
local function update_text(filename)
    local updated = false

    if filename and filename ~= "" then
        -- read text from file
        text = readfile(filename, max_text_size)
        updated = true
    elseif lines then
        -- concatenate and reset lines array
        text = table.concat(lines, "\n")
        lines=nil
        -- crop text if necessary
        text = crop(text, max_text_size)
        updated = true
    end

    -- wrap text around if configured
    if updated and wrap_around then
        local first_words = string.match(text, "^%s*%S+%s+%S+%s+%S+%s+%S+")
        if first_words then
            text = text .. " " .. first_words
        else
            -- very short text (less than four words)
            text = text .. " " .. text
        end
    end
end

----- Exported functions -----------------------------------------------

-- Selects the classes to use for all following operations (until a new
-- set of classes is selected). Specify two or more classes as arguments.
-- Returns true on success.
function classes(...)
    -- reset old values
    class_names = {}
    dbset.classes = {}
    class_indexes = {}

    -- update lists of classes
    for index, class in ipairs(arg) do
        class_names[index] = class
        -- complete file name for dbset:
        dbset.classes[index] = classdir .. class .. class_ext
        class_indexes[class] = index   -- inverted mapping from name to index
    end
    -- check that there are at least 2 classes
    assert(#class_names > 1, "Not enough classes")
end

-- Creates new databases for the active classes.
-- Returns true on success.
function create()
    if #dbset.classes == 0 then
        error("No classes defined", 2)
    else
        assert(osbf.create_db(dbset.classes, buckets))
    end
end

-- Deletes the databases for all active classes.
function destroy()
    if #dbset.classes == 0 then
        error("No classes defined", 2)
    else
        assert(osbf.remove_db(dbset.classes))
    end
end

-- Reads standard input until the specified delimiter_line is encountered.
-- Reads until the next empty line if delimiter_line is nil or empty.
-- The read lines (excluding the delimiter_line) are stored as standard
-- argument for subsequent train and classify operations.
function readuntil(delimiter_line)
    delimiter_line = delimiter_line or ""  -- default is empty string
    text = nil                             -- clear old text + lines array
    lines = {}
    local line

    -- read lines until finding delimiter_line
    while true do
        line = io.read()
        if (line == nil) or (line == delimiter_line) then break end
        lines[#lines + 1] = line
    end

    if last_filename == "" then    -- empty string denotes lines array:
        -- reset since its contents have changes
        last_filename = nil
    end
end

-- Classifies a file. If the filename argument is omitted/nil, the text read
-- by the last |readuntil| or |classify| operation (whichever came later) is
-- trained instead. The special filename "-" means to read from standard
-- input until the end of input (must be the last command).
--
-- Returns a table with the following name=value pairs:
--
-- - class = the most likely class, selected from the list of active classes
-- - reinforce = a boolean value specifying whether or not the caller should
--   reinforcement-train the file (i.e. whether the classifier is unsure of
--   it's decision)
-- - prob = the probability of the most likely class (a real number in the
--   [0.0, 1.0] range)
-- - probs = the probabilities of all active classes (an array of real
--   numbers)
-- - pR = the probability ratio (pR) of the first of the active classes
--   (*not* of the most likely class), compared to the combined probability of
--   all other active classes; will be positive if the first class is the
--   most likely one, negative otherwise
function classify(filename)
    update_text(filename)
    local pR, p_array, i_pmax =
        assert(osbf.classify(text, dbset, classify_flags))

    local result = {}
    result.class = class_names[i_pmax]
    result.reinforce = (math.abs(pR) <= threshold)
    result.prob = p_array[i_pmax]
    result.probs = p_array
    result.pR = pR

    -- Store determined class + pR + filename (if any) for next train
    last_classify_result = result
    last_filename = filename or "" -- empty string denotes lines array
    return result
end

-- Trains the specified file as an instance of the specified class, if
-- necessary. If the filename argument is omitted/nil, the text read by the
-- last |readuntil| or |classify| operation (whichever came later) is
-- trained instead. The special filename "-" means to read from standard
-- input until the end of input (must be the last command).
--
-- Training is skipped as unnecessary if a call to |classify(filename)|
-- returns the correct class and no need for reinforcement. The result of the
-- last |classify| operation is cached and will be inspected if this method is
-- subsequently invoked on the same file/text; otherwise this method will
-- internally call |classify| to determine whether training is necessary.
--
-- Returns a table with name=value pairs describing the training operation:
--
-- - misclassified = true if this training operation corrects a
--   misclassification, false otherwise
-- - reinforced = true if training was necessary for reinforcement, false
--   otherwiese
--
-- Both |misclassified| and |reinforced| will be false if (and only if)
-- training has been skipped as unnecessary; |misclassified| and |reinforced|
-- will never both be true.
function train(class, filename)
    -- determine class index + ensure that class is valid
    local index = class_indexes[class]
    if not index then
        error("Not an active class: " .. class, 2)
    end

    local filename = filename or "" -- empty string denotes lines array
    local classify_result

    if filename == last_filename or filename == "" then
        -- re-use stored result of last classification + update text
        --io.write("Reusing stored result for '" .. filename .. "'\n")
        classify_result = last_classify_result
        update_text(filename)
    else
        -- invoke classify (will also call update_text for us)
        --io.write("Invoking classify for '" .. filename .. "'\n")
        classify_result = classify(filename)
    end

    local misclassified, reinforce

    -- check if misclassification or if reinforcement needed
    if classify_result.class == class then
        misclassified = false
        reinforce = classify_result.reinforce
    else
        misclassified = true
        reinforce = false
    end

    -- train if necessary
    if misclassified or reinforce then
        assert(osbf.learn(text, dbset, class_indexes[class], learn_flags))
    end

    -- populate + return result table
    local result = {}
    result.misclassified = misclassified
    result.reinforced = reinforce
    return result
end

-- Returns a string with statistics reports for a given class; or for all
-- active classes if no class parameter is given.
function stats(class)
    if class then  -- return result for specified class
        return dbfile_stats (class)
    else   -- concatenate and return reports for all active classes
        local reports = {}
        for _, class in ipairs(class_names) do
            reports[#reports + 1] = dbfile_stats(class)
        end
        return table.concat(reports)
    end
end
