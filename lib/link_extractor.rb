require 'nokogiri'
require 'open-uri'
require 'uri'


class LinkExtractor

  def initialize(url,content)
    @url = url
    @content = content
  end
  
  def hostname(url)
    URI.parse(url).host rescue nil
  end
  
  def extract
    begin
      doc = Nokogiri::HTML(@content) 
      @link_list = doc.css('a').map{|link| clean_link(link) }.compact.uniq
    rescue
      []
    end
  end
  
  def clean_link(link)
    link_url = link['href'] rescue nil
    link_url if link_url && link_url.match(/^https?:\/\/\w+\/?/) && hostname(link_url) != hostname(@url)
  end
  

  
end



