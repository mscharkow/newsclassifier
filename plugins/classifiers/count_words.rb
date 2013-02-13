#!/usr/bin/env ruby
# Read every line, do something, output result
ARGF.each do |line|
    puts line.split.size # Simple word count
end