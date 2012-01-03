class Document < ActiveRecord::Base
  has_one :body, :dependent=>:destroy
  delegate :raw_content, :summary, :to=>:body
  
  cattr_reader :per_page
  @@per_page = 20
  
  belongs_to :source, :counter_cache => true
  has_many :classifications, :dependent => :destroy
  has_many :categories, :through=>:classifications
  
  validates_presence_of :source_id
  validates_presence_of :title
  validates_uniqueness_of :url, :scope=>:source_id
  
  before_save :sanitize_content
  before_create :build_body
  
  scope :by_project, lambda { |project| project.samples.active.first ? where(['id  in (?)', project.samples.active.first.items]) : where(['source_id in (?)', project.sources]) }
  
  scope :for_user, lambda{|user| where(['documents.id NOT in (?)',user.documents.map(&:id)])}
  scope :no_raw_content, :joins => :body, :conditions => ['bodies.raw_content is ?', nil]
  scope :no_content, :joins => :body, :conditions => ['bodies.content is ?', nil]
  scope :without_ids, lambda { |ids| {:conditions=> ['id not in (?)', ids ]}}
  scope :with_ids, lambda { |ids| {:conditions=> ['id  in (?)', ids ]}}
 
 
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
    begin
      html = open(u).readlines.join(' ')
      body.update_attribute(:raw_content,html) if html
    rescue OpenURI::HTTPError
      if u==print_url && u != url
        get_url_content(url)
      end
    end
    raw_content
  end
  
  def get_classifications(permanent=nil)
    cl = []
    source.project.classifiers.auto.find_each(:include=>:categories){|c|cl << c.classify(self,permanent)}
    cl
  end
  
  def update_body(*args)
    body.update_attributes(*args) and touch
  end
  
  # Document content 
  
  def content 
    Rails.cache.fetch(cache_key+'content'){body.get_content}
  end
  
  def teaser(size=100)
    @teaser ||= content.split(' ')[0..size].join(' ')+' ...' rescue ''
  end
    
  def fulltext
    @fulltext ||= "#{title} #{content}".gsub(/<\/?[^>]*>/, "").strip
  end
  
  def stats
    {:words=>fulltext.words.size,:ari => fulltext.ari.to_i,:sentences => fulltext.sentences}
  end
  
  def links
    Rails.cache.fetch(cache_key+'links'){LinkExtractor.new(url,raw_content).extract}
  end

  # Sanitize, save and export
    
  def sanitize_content
    coder = HTMLEntities.new
    self.title = coder.decode(title.gsub(/\s+/,' ').gsub(/<\/?[^>]*>/,"").strip)
    self.pubdate = Time.now unless pubdate
    self.url = url.try(:strip)
  end
  
  def export
    to_json(:include=>{:body=>{:only=>[:summary,:content,:raw_content]},
                        :source=>{:only=>[:name,:metadata,:urls]}
                      })
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
