class Source < ActiveRecord::Base
  # Class methods
  serialize :metadata, Hash
  
  include URLHelper
  
  belongs_to :project
  has_many :documents, :dependent=>:destroy
  
  validates_presence_of :name, :message => "can't be blank"
  
  # For quick creation using FeedFinder
  attr_accessor :site_url
  before_validation :clean_metadata
  
  def create_from_url
    return if site_url.blank?
    if feeds = FeedFinder.feeds(site_url)
      self.urls = [urls,feeds[0]].flatten.compact.join("\n")
      self.name = Feedzirra::Feed.fetch_and_parse(urls[0]).title || site_url
      self
    else
      false
    end
  end
  
  def clean_metadata
    self.metadata ||= {:print_regexp=>'',:fulltext_from_url=>'',:filter=>'',:ignore_charset=>''}
    self.metadata.each do |k,v|
      self.metadata[k] = v.strip
    end
  end
  

  
  def export
    to_json(:include=>{
              :documents=>{:include=>
                              {:body=>{:except=>[:document_id,:created_at,:updated_at,:id]}
                          },:except => [ :id, :source_id,:classifications_count,:updated_at]}
            },:except => [ :id,:documents_count,:project_id,:updated_at ])
  end
  
  
  # Split url list
  def urls
    attributes['urls'].try(:split) || []
  end
  
  
  #Document stats
  def last_pubdate
    documents.first(:order=>'pubdate DESC').try(:pubdate)
  end
  
  def word_avg
    documents.average(:wordcount).to_i
  end
  
  def stats(strf = "%Y%m")
    begin
      documents.count(:all,:group=>"DATE_FORMAT(pubdate,'#{strf}')").sort_by{|a|a[0]}
    rescue
      documents.count(:all,:group=>"strftime('#{strf}',pubdate)").sort_by{|a|a[0]}
    end
  end
  
  

  
  def conv(text)
    return text if !metadata[:convert_charset] || @charset=='utf-8'
    Iconv.conv('utf-8', @charset, text)
  end
  
  def import_feeds
    urls.each do |url|
      import_from_feed(url)
    end
  end
  
  
  def import_from_feed(url)    
    feed = Feedzirra::Feed.fetch_and_parse(url)    
    fe = feed.entries rescue []
    fe.each do | entry |
      u = final_url(entry.url).try(:strip)
      break unless u
      u = u.split('?')[0] if u.match('feedburner')
      u = u.split('#')[0]
      doc = documents.find_or_create_by_url(u)
      doc.update_attributes(
        {:title => entry.title,
         :pubdate => (entry.published || doc.pubdate)
        })
      doc.create_body unless doc.body
      if metadata['fulltext_from_url'] == "1"
        doc.body.update_attribute(:summary,entry.summary)
        Resque.enqueue(DocumentDownload, doc.id) if doc.raw_content.blank?
      else
        doc.body.update_attribute(:content, (entry.content||entry.summary))
        doc.get_classifications(true) if doc.new_record?
      end
    end
  end
  

end




