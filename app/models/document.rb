class Document < ActiveRecord::Base
  has_one :body, :dependent=>:destroy
  delegate :raw_content, :summary, :content, :to=>:body
  
  paginates_per 20
  
  belongs_to :source, :counter_cache => true
  has_many :classifications, :dependent => :destroy
  has_many :categories, :through=>:classifications
  
  validates_presence_of :source_id
  validates_presence_of :title
  validates_uniqueness_of :url, :scope=>:source_id
  
  before_save :sanitize_content
  before_create :build_body
  
  scope :by_project, 
  lambda { |project| project.samples.active.first ? where(['id  in (?)',
  project.samples.active.first.items]) : where(['source_id in (?)', 
  project.sources]) }
  
  scope :for_user, 
  lambda{|user| where(['documents.id NOT in (?)',user.documents.map(&:id)])}
  
  scope :no_raw_content, 
  :joins => :body, :conditions => ['bodies.raw_content is ?', nil]
  scope :no_content, 
  :joins => :body, :conditions => ['bodies.content is ?', nil]
  
  scope :without_ids, lambda { |ids| {:conditions=> ['id not in (?)', ids ]}}
  scope :with_ids, lambda { |ids| {:conditions=> ['id  in (?)', ids ]}}
 
  scope :title_matches, lambda {|regexp| find_by_regexp(:title,regexp)}
  scope :url_matches, lambda {|regexp| find_by_regexp(:url,regexp)}
  scope :summary_matches,
  lambda {|regexp|joins(:body).find_by_regexp('bodies.summary',regexp)}
  scope :content_matches,
  lambda {|regexp|joins(:body).find_by_regexp('bodies.content',regexp)}
  scope :raw_content_matches,
  lambda{|regexp|joins(:body).find_by_regexp('bodies.raw_content',regexp)}
  
  def convert_charset(to='utf-8',from='iso-8859-1')
    self.update_attribute(:title, Iconv.conv(to,from,title))
    self.body.update_attributes(
      :summary => Iconv.conv(to,from,body.summary), 
      :raw_content => Iconv.conv(to,from,body.raw_content)
      )
  end

  def print_url
    regex = source.metadata[:print_regexp]
    if regex.blank?
      url
    else
      re = regex.split 
      url.gsub(Regexp.new(re[0]),re[1])
    end
  end
  
  def get_url_content(u = print_url)
    if ( open(u,:read_timeout=>2){|f|f.content_type} rescue nil ) == 'text/html'
      if html = open(u,:read_timeout=>2).read
        body.update_attributes(:raw_content=>html)
      end
    else
      get_url_content(url) if print_url != url
    end
  end
  
  
  # Document content 
  def teaser(size=100)
    @teaser ||= content.split(' ')[0..size].join(' ')+' ...' rescue ''
  end
    
  def fulltext
    @fulltext ||= "#{title} #{content}".gsub(/<\/?[^>]*>/, "").strip
  end
  
  def to_csv
    "#{id};#{clean(title)} #{clean(content)}\n"
  end
  
  def clean(text)
    return if text.blank?
    text = text.gsub('"','').gsub(/\s+/,' ').gsub(';',',').strip
    "#{text}"
  end
  
  def stats
    {:words=>fulltext.words.size,:ari => fulltext.ari.to_i,:sentences => fulltext.sentences}
  end
  
  
  # Link Extraction
  def links
    Rails.cache.fetch([cache_key, 'links']){LinkExtractor.new(url,raw_content).extract}
  end
  
  def unique_links
    Rails.cache.fetch([cache_key, 'unique_links']) do 
      prev_links = source.documents.where(['id < ?',self]).limit(50).map(&:links)
      next_links = source.documents.where(['id > ?',self]).limit(50).map(&:links)
      links - [prev_links + next_links].flatten.uniq
    end
  end

  # Image Extraction
  def images
    Rails.cache.fetch([cache_key, 'images']) do 
      Nokogiri::HTML(raw_content).css('img').map { |i| {:src=>i['src'],:alt=>i['alt'], :size=>(i['width'].to_i * i['height'].to_i)} }.compact
    end
  end
  
  def unique_images
    Rails.cache.fetch([cache_key, 'unique_images']) do 
      prev_images = source.documents.where(['id < ?',self]).limit(50).map(&:images)
      next_images = source.documents.where(['id > ?',self]).limit(50).map(&:images)
      images - [prev_images + next_images].flatten.uniq
    end
  end
  
  
  # Sanitize, save and export
    
  def sanitize_content
    coder = HTMLEntities.new
    self.title = coder.decode(title.gsub(/\s+/,' ').gsub(/<\/?[^>]*>/,"").strip)
    self.pubdate = Time.now unless pubdate
    self.url = url.try(:strip)
  end
  
  def as_json(options={})
    super :only=>[:title,:url, :pubdate], :include=>{:body=>{:only=>[:summary,:content,:raw_content]}}
  end
  
  def write_to_file(path=nil)
    path ||= '/tmp/articles'
    Dir.mkdir path rescue nil
    f_raw = File.new("#{path}/#{gf_id}.html",'w')
    f_full = File.new("#{path}/#{gf_id}.txt",'w')
    f_raw.write(raw_content) && f_raw.close if raw_content
    f_full.write(fulltext) && f_full.close
  end
  
  
  def find_duplicates
    source.documents.all(:conditions=>['id < ? and pubdate > ? and title = ?',id,pubdate-1.day,title])
  end
  
  def cats_for_classifiers(classifiers)
    catlist = {}
    classifiers.each{|c| catlist[c.id] = c.get_classification_for(self) }
    #categories.each{|cat| catlist[cat.classifier.id] = cat.val }
    catlist
  end
  
  # document stats
  
  def self.stats_for_month(num=1,*args)
    with_scope :find => { :conditions =>  [ 'pubdate between ? and ?', num.months.ago, (num-1).months.ago] } do
      count(*args)
    end
  end
  
  # Various document collections
  
  def self.for_coding(user,size=100)
   where
   [1..size] || []
  end
  
  def self.for_reltest(project,user,size=100)
    a = Document.by_project(project).with_ids(user.fellows.map{|f|f.documents}.flatten.uniq).find(:all,:select=>:id).sort_by{rand}
    b = a-user.documents rescue a
    b[1..size] || []
  end
  
  def self.for_active_learning(project,user,classifier,size=100)
    docs = self.for_coding(project,user).map{|d|[d,classifier.classify(d.reload)]}
    a = docs.map{|d|d[0] if d[1][1].abs <= 2}.compact
    a[1..size] || []
  end
  
  def self.mixed(project,user,size=100)
    a1 = Document.for_coding(project,user,100-project.reli_test_ratio.to_i) 
    a2 = Document.for_reltest(project,user,project.reli_test_ratio.to_i) 
    (a1+a2).uniq.sort_by{rand}[1..size]
  end
  
end
