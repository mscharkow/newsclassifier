require 'uri'
require 'open-uri'
require 'rubygems'
require 'nokogiri'

module FeedFinder
  
  # Return array of all feeds at url
  def self.feeds(url)
    uri = url_to_uri(url)
    return [url] if feed?(uri)
    feeds = find_feed_links(uri) rescue nil
    return nil if feeds.blank?
    feeds
  end
  
  private
  
  def self.feed?(uri)
    feed_url?(uri.to_s) && points_to_feed?(uri)
  end
  
  # Check if an url looks like a feed url
  def self.feed_url?(url)
    (url =~ /\.xml|atom|rss|rdf|feed|feedproxy|feedburner/) != nil
  end
  
  # Check if an url really points to a proper feed
  def self.points_to_feed?(uri)
    data = download_from_uri(uri)
    (data =~ /<rss|<feed|<rdf|<RSS|<FEED|<RDF/) != nil
  end
  
  # Get possible feed links from uri
  def self.find_feed_links(uri)
    doc = Nokogiri(download_from_uri(uri))
    feeds = find_autodiscovery_links(uri,doc)
    feeds = find_feed_anchor_links(uri,doc) if feeds.empty?
    feeds.find_all { |f| points_to_feed?(f) }
  end
  
  # Find feeds through <link>s in <head>
  def self.find_autodiscovery_links(uri,doc) 
    feeds = []
    (doc/:head/:link).each do |e|
      if e['rel'] == 'alternate' && e['type'] =~ /rss|atom|xml|feed/
        feeds << uri.merge(e['href']).to_s
      end
    end
    feeds.uniq
  end
  
  # Find feeds through <a>s in <body>
  def self.find_feed_anchor_links(uri,doc)
    feeds = []
    (doc/:body/:a).each do |a|
      if feed_url?(a['href'])
        begin
          link = URI.parse(a['href'])
          if link.relative? || link.host.to_s.include?(uri.host.to_s)
            feeds << uri.merge(a['href']).to_s
          end
        rescue
        end
      end
    end
    feeds.uniq
  end
  
  # Download html via url object
  def self.download_from_uri(uri)
    begin
      open(uri, "User-Agent" => "Ruby/#{RUBY_VERSION}").read
    rescue Exception => e
      raise ArgumentError.new("Could not get content from url: #{uri} (#{e})")
    end
  end  
  
  # Convert any url to an uri object
  def self.url_to_uri(url)
    begin
      if url =~ /http:\/\//
        URI.parse(url)
      else
        URI.parse(('http://' + url).gsub('///','//'))
      end
    rescue Exception => e
      raise ArgumentError.new("Could not parse url: #{url} (#{e})")
    end
  end
  
end