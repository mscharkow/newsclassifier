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
-- This is the main executable that provides a command-line interface
-- for the moonfilter module/class (it could also easily be extended to work
-- with other modules).
--
-- See the README file/website for usage documentation. 
-- See moonfilter.lua for versioning information.

----- Load required modules --------------------------------------------

local m = require "moonfilter"

---- Utility functions -------------------------------------------------

-- Gets or sets the value of field in obj (which must be of the type given as
-- field_type). If param_list is the empty table, the value of the field is
-- returned without changing it. Otherwise the value is updated and then
-- returned.
--
-- If field_type is "table", the full param_list is assigned as value.
-- Otherwise field_type must be one of "number", "string", or "boolean"
-- and param_list must have exactly one value which is converted to the
-- required type and then assigned to the field.
function setorget(field_type, obj, field, param_list)
    if #param_list > 0 then -- update
        if field_type == "table" then   -- assign complete table
            obj[field] = param_list
        else   -- try to convert single parameter to correct type
            if #param_list > 1 then
                error("Cannot assign multiple values to field")
            end

            local newval
            if field_type == "string" then
                newval = tostring(param_list[1])
            elseif field_type == "number" then
                newval = tonumber(param_list[1])
            elseif field_type == "boolean" then
                newval = tobool(param_list[1])
            else
                error("Cannot modify field of type " .. field_type)
            end

            if newval then -- assign new value
                obj[field] = newval
            else           -- conversion failed
                error("Cannot convert '" .. tostring(value)
                            .. "' to " .. field_type)
            end
        end
    end

    -- return value
    return obj[field]
end

-- Tries to convert its argument to a boolean. The strings "true" and "false"
-- are converted in the obvious way, and boolean values are returned
-- unchanged. In all other cases, nil is returned
function tobool(value)
    if value == "true" then
        return true
    elseif value == "false" then
        return false
    elseif type(value) == "boolean" then
        return value
    else
        return nil
    end
end

-- Split text into a list consisting of the strings in text,
-- separated by strings matching delimiter (which may be a pattern).
-- By default, "%s+" is used as pattern, i.e. strings are separated by
-- whitespace. Strings containing the delimiter pattern or starting with
-- a double quote must be enclosed in "double quotes"; double quotes
-- and backslashes in such quoted strings must be backslash-escaped).
function split_params(text, delimiter)
    delimiter = delimiter or "%s+"
    local list = {}
    if not text then    -- return immediately if text is nil
        return list
    end
    if string.find("", delimiter) then  -- this would result in endless loops
          error("delimiter matches empty string!")
    end
    local nextpos = 1
    local pos, endpos, first, last, endqfirst, endqlast
    local str
    local done = false
    repeat
        pos = nextpos
        if string.find(text, '^"', pos) then
            -- start of quoted string: look for ending quote, possibly
            -- preceded by an even number of backslashes
            endqlast = pos
            repeat
                endqfirst, endqlast = string.find(text, '\*"$', endqlast + 1)
            until endqfirst == nil or (endqlast - endqfirst) % 2 == 0

            if endqfirst then   -- got it!
                -- ensure that a delimiter or end-of-string follows
                if endqlast == string.len(text) then
                    done = true     -- this is the last token
                else
                    -- ensure that a delimiter follows
                    first, last = string.find(text,
                                  "^" .. delimiter, endqlast + 1)
                    if first then
                        nextpos = last + 1
                    else
                        error("Missing delimiter after end quote: "
                              .. string.sub(text, last))
                    end
                end

                -- exclude quotes and unescape backslash sequences
                str = string.sub(text, pos + 1, last - 1)
                str = string.gsub(str, '\(.)', '%1')
            else
                error("Missing end quote: " .. string.sub(text, pos))
            end
        else
            -- unquoted string: look for next delimiter
            first, last = string.find(text, delimiter, pos)
            if first then
                endpos = first - 1
                nextpos = last + 1
            else    -- this is the last token
                endpos = string.len(text)
                done = true
            end
            str = string.sub(text, pos, endpos)
        end

        -- ignore trailing delimiter (skip empty match at end of text)
        if not (done and string.len(str) == 0) then
            list[#list+1] = str    -- append
        end
    until done
    return list
end

-- Writes an object, supporting strings, numbers, booleans, tables (including
-- nested tables), and nil.
--
-- Tables are enclosed in brackets, table members are separated by whitespace:
-- "[ member1 member2 ...  ]" .  Key/value pairs are separated by an equals
-- sign: "key=value".  Strings are only "quoted" when they contain whitespace
-- or one of: ="'[]{} (equals sign, full or half quote, square or curly
-- brackets); Full quoted and backslashes in quoted strings are backslash
-- escaped. Booleans are serialized as "true" or "false" and nil values are
-- serialized as "nil" (without quotes).
--
-- If no |out| file to write to given, the object will be written to io.output
-- (standard out).
-- Set |noOuterBrackets| to true to suppress the brackets around the outmost
-- table.
function write_object(o, noOuterBrackets, out)
    out = out or io.output()

    if type(o) == "number" then
        out:write(o)
    elseif type(o) == "string" then
        -- escape string if it contains bad characters: whitespace or ="'[]{}
        if string.find(o, "[][%s=\"'{}]") then
            out:write(string.format("%q", o))
        else
            out:write(o)
        end
    elseif type(o) == "table" then
        if not noOuterBrackets then
            out:write("[")
        end
        local prepend = ""
        local i = 1
        for k,v in pairs(o) do
            out:write(prepend)
            -- serialize keys + values recursively,
            -- skipping key for regular array indexes (1, 2, 3 etc.)
            if k ~= i then
                write_object(k, false, out)
                out:write("=")
            end
            write_object(v, false, out)
            i = i+1
            prepend = " "   -- separate members by a space
        end
        if not noOuterBrackets then
            out:write("]")
        end
    elseif o == true then
        out:write("true")
    elseif o == false then
        out:write("false")
    elseif o == nil then
        out:write("nil")
    else
        error("Cannot print a " .. type(o))
    end
end

----- Main program -----------------------------------------------------

local line, command, param_str, param_list, command_type
local status, result
local argpos = 1   -- position in the command-line arguments (arg table)
local done = false

-- Main loop: read + process commands.
repeat
    -- read command incl. parameters
    if argpos <= #arg then
        line = arg[argpos] -- process next command-line argument
        argpos = argpos + 1
    else
        line = io.read()   -- process next line from stdin
    end

    if not line then   -- reached end of stdin: terminate loop + program
        break
    end

    -- split in command and (optional) parameters
    command, param_str = string.match(line, "^%s*(%S+)%s*(%S*.*)")
    param_list = split_params(param_str)
    if command then     --  handle command, skipping empty lines
        command_type = type(m[command])

        if command_type == "nil" then
            -- unknown command: report error unless I can handle it myself
            if command == "exit" then  -- shutdown
                done   = true
                status = true
                result = nil
            else   -- unknown command error
                status = false
                result = "unknown command: " .. command
            end
        elseif command_type == "function" then
            -- Invoke function with given parameters
            status, result = pcall(m[command], unpack(param_list))
        else
            -- set or get variable value
            status, result =
                pcall(setorget, command_type, m, command, param_list)
        end

        io.write(command)   -- print command name
        if status then -- print ok + result (if not nil)
            io.write(" ok")
            if result ~= nil then
                io.write(": ")
                write_object(result, true)    -- no need for outer brackets
            end
        else           -- print fail + result (will contain the error message)
            io.write(" failed: ")
            io.write(tostring(result))   -- ensure it's really a string
        end
        io.write("\n")
        io.flush()
    end
until done
