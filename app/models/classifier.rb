class Classifier < ActiveRecord::Base
  attr_accessor :reltest
  attr_accessor :options_mask 
      
  belongs_to :project
  has_many :categories, :dependent => :destroy
  accepts_nested_attributes_for :categories,:reject_if => lambda { |a| a[:name].blank? }, :allow_destroy => true
  
  has_many :classifications
  has_many :documents, :through => :classifications
  has_and_belongs_to_many :users
  
  serialize :parts
  serialize :reliability

  scope :manual, where(:type=>nil)
  scope :auto, where(:type=>'DictionaryClassifier')
    
  validates_presence_of :project_id, :message => "must be set."
  validates_presence_of :name, :message => "can't be blank"
  validates_presence_of :parts, :message => "can't be blank"
  validates_uniqueness_of :name, :scope=>:project_id
# validates_size_of :categories, :minimum => 2,:on => :update, :message => 'at least 2 categories needed.'
#  after_save :save_categories
  before_save :cleanup_parts
  
  def cleanup_parts
    self.parts = parts.map{|p|p if default_parts.include?(p)}.compact.uniq
  end
    
  def default_parts
     %w(title summary content raw_content url)
  end
  
  def variable_name
    name.gsub(/\s+/,'_').downcase
  end
  
  
  def manual_reliability
    reliability[:manual][0] rescue nil
  end
  
  def auto_reliability
    reliability[:auto][0] rescue nil
  end
  
#  def cats=(cats)
#    cats.each do | cat |
#      if cat[:id].blank?
#        categories.build(cat) unless cat.values.all?(&:blank?)
#      else
#        category = categories.detect {|c| c.id == cat[:id].to_i}
#        category.attributes = cat
#      end
#    end
#  end
#  
#  
#  
#  def save_categories
#    categories.each do |c|
#      if c.should_destroy?
#        c.destroy
#      else
#        c.save(false)
#      end
#    end
#  end
  

  
  
  def relevant_content(document)
    parts.map{|p| document.send(p)}.join("\n")
  end
  
  
  def get_classification_for(document)
    cl = classifications.manual.find_all_by_document_id(document).sort_by{rand}[0] || classifications.auto.find_all_by_document_id(document).sort_by{rand}[0] 
    if cl.blank? 
      if self.class != DictionaryClassifier
        classifications.create(:category_id=>classify(document)[0],:document=>document)  rescue nil
      else
        classify(document)  rescue nil
      end
    else
      cl
    end
  end
  
  def all_classifications_for(document)
    classifications.find_all_by_document_id(document)
  end
  
  def classify(document,permanent=false)
    content = relevant_content(document)
    #classify_mr(content)
  end
  
  
  def classify_all
    classifications.auto.destroy_all
    Document.by_project(project).find_in_batches do | docs|
      cl = classify_batch(docs)
      d = docs.zip(cl) rescue []
      d.each  do |doc|
        classifications.create(:category_id=>doc[1],:document=>doc[0])  rescue nil
      end
    end
  end
  
  def train(document,category)
    content = relevant_content(document)
    train_mr(content,category.id)
  end
  
  def train_batch(classifications)
    all = classifications.sort_by{rand}.map{|c|train_mr(relevant_content(c.document),c.category.id,1)}
    all.in_groups_of(100) do |a|
      out = run_mr(a.join("\n"))
      #puts out
    end
  end
  
  def classify_batch(documents)
    out = []
    documents.in_groups_of(200) do |dl|
      input = []
      dl.compact.each do |document|
        content = relevant_content(document)
        input << "readuntil <EOF>\n#{content}\n<EOF>\nclassify" 
      end
      out << run_mr(input.join("\n"))
    end
    out = out.join
    classes = out.scan(/class=(\w+)/).flatten
    pR = out.scan(/pR=(-?\w+)/).flatten.map{|i|i.to_i}
    return classes if classes.size == documents.size
  end
  
#---- Reliability

  def test_reliability
    self.reliability = {}
    r = Reltest.new(self)
   # reliability[:manual] = r.manual rescue [0,0]
  #  save
    reliability[:auto] = r.k_fold rescue [0,0]
    #reliability[:problematic] = r.problems rescue []
    #reliability[:difficult] = r.difficult rescue []
    save
  end
  
  def difficult_documents
    documents.uniq.map{|d| d if self.all_classifications_for(d).map{|a|a.category_id}.uniq.size > 1}.compact
  end
 
  
#---- MR Stuff  
  
  def train_mr(content,category_id,batch=0)
    category_id = "rel_#{reltest}_#{category_id}" if reltest
    return if content.blank?
    input =  "readuntil <EOF>\n#{content}\n<EOF>\nclassify\ntrain #{category_id}"
    if batch == 1
      input
    else
     run_mr(input).split("\n")[3].split[1] == 'ok:' 
    end
  end
  
  
  def classify_mr(content)
    return if content.blank?
    input =  "readuntil <EOF>\n#{content}\n<EOF>\nclassify"
    out = run_mr(input)
    res = out.split("\n")[-1].split(/\S+=/).map{|a|a.strip}
    if res[0] =='classify ok:'
      cat,pR = res[3].to_i,res[4].to_i
    else 
      res
    end
  end
  
  def create_classes
    #return if Rails#env == 'test'
    run_mr('create')
  end
  
  def destroy_classes
    #return if Rails#env == 'test'
    run_mr('destroy')
  end
  
  
  def run_mr(command)
    if reltest
      classes = categories.collect{|c|"rel_#{reltest}_#{c.id}"}.join(' ')
    else
      classes = categories.collect{|c|c.id}.join(' ')
    end
    command = "classes #{classes}\n"+command+"\n"
    mr = IO.popen('./bin/mr','w+')
    mr.write(command.gsub('"','\"'))
    mr.close_write
    c = mr.read
    mr.close
    c.gsub("rel_#{reltest}_",'')
  end
  
  
  # Options
   OPS= %w[raw stop stem short notitle]

   def options=(options)
     self.options_mask = (options & OPS).map{ |r| 2**OPS.index(r) }.sum
   end


   def options(opt = false)
     self.options_mask = 0 unless options_mask
    oa = OPS.reject { |r| ((options_mask || 0) & 2**OPS.index(r)).zero? }
    if opt
     oa.include?(opt.to_s)
    else
     oa
    end
   end
end


