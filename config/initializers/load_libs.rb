require 'string_extensions'
require 'feed_finder'
require 'link_extractor'
require 'url_helper'

require 'iconv'
require 'open-uri'

class Array
  def find_dups
    uniq.map {|v| (self - [v]).size < (self.size - 1) ? v : nil}.compact
  end
end
