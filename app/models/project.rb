class Project < ActiveRecord::Base
  serialize :metadata
  attr_accessor :admin
  
  def self.quick_create(name,email,permalink=nil)
    project = self.create!(:name=>name,:permalink=>permalink) and
    user = project.users.create!(:email=>email,:password=>"pw4#{email}") and
    user.update_attribute(:admin,true)
  end
  
  # AR associations  
  has_many :users
  has_many :sources
  has_many :classifiers
  
  has_many :samples do
    def active(reload = false)
      @active = nil if reload
      @active ||= find(:all, :conditions => ["active = ?", true])
    end
  end

  #validations and callbacks
  
  before_create :set_defaults
  def set_defaults
    self.permalink ||= name.gsub(/[^A-z0-9]/, '_').downcase if name
    self.metadata ||= Hash.new(nil)
    self.metadata[:reli_test_ratio] ||= 10
  end
  
  validates_presence_of :name, :message => "can't be blank"
  validates_format_of :permalink, :with => /^\w+$/, :message => "must be one word"
  validates_uniqueness_of :permalink, :message => "must be unique"
  
  # convenience AR queries
  
  def documents
    if s = samples.active.first
      Document.where(['documents.id in (?)',s.items])
    else
      Document.where(['source_id in (?)',sources])
    end
  end
  
  def classifications
    Classification.where(['classifier_id in (?)',classifiers])
  end

  def csv
    out = Rails.cache.fetch(csv_cache_key){Output.new(self).to_csv}
    File.open("/tmp/documents_#{id}.csv",'w'){|f|f.write(out)}
    out
  end
  
  def write_weekly(d=nil)
    d ||= Time.now
    t1 = d.beginning_of_week
    t2 = t1+1.week
    filename = t.strftime('%Y-%m-%d')
    d = Dir.mkdir("/tmp/weekly/#{permalink}/#{filename}") unless Dir.exists?("/tmp/weekly/#{permalink}/#{filename}")
    f = File.new("/tmp/weekly/#{permalink}/#{filename}/#{filename}.csv",'w')
    f.write(Output.new(self).to_csv(['pubdate >= ? and pubdate < ?',t1,t2]))
    f.close
    Document.by_project(self).find_each(:conditions=>['pubdate >= ? and pubdate < ?',t1,t2]) do |d|
      d.write_to_file("/tmp/weekly/#{permalink}/#{filename}/articles")
    end
  end
  
  
  def complete_classifications
    reset_csv
    classifiers.each{|cl|cl.send_later(:classify_all)}
  end
  
#  private
  
  def csv_cache_key
    "project-#{cache_key}-#{samples.active.first.cache_key rescue nil}-#{documents.last.cache_key rescue nil}-#{classifications.last.cache_key rescue nil}"
  end
  
  
end
