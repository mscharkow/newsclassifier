#!/usr/bin/env ruby
require 'textstats'
ARGF.each do |line|
  puts line.sentences rescue 0
end


