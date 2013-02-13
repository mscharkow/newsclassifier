#!/usr/bin/env ruby
require 'textstats'
ARGF.each do |line|
    puts line.ari.to_i rescue 0
end


