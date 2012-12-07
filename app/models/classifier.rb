class Classifier < ActiveRecord::Base
  attr_accessor :reltest
  attr_accessor :options_mask 
  
  cattr_reader :per_page
  @@per_page = 20
      
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

  before_save :cleanup_parts
  
  def cleanup_parts
    self.parts = parts.map{|p|p if default_parts.include?(p)}.compact.uniq
  end
    
  def default_parts
     %w(title summary content raw_content url)
  end
  
  def variable_name
    name.gsub(/\W+/,'_').downcase
  end

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

# Reliability
  
  def difficult_documents
    documents.uniq.map{|d| d if self.all_classifications_for(d).map{|a|a.category_id}.uniq.size > 1}.compact
  end
  
  def manual_reliability
    Reltest.new(self).manual
  end

  def auto_reliability
    reliability[:auto][0] rescue nil
  end

  def agreement(data)
    (data.map{|i|i.uniq.size == 1 ? 1:0}.inject(:+).to_f/data.size).round(2)
  end

# Supervised Classification

  def classify(document,permanent=false)
    content = relevant_content(document)
    @cl.classify(content)
  end

  def train(classification)
    content = relevant_content(classification.document)
    @cl.train(classification.category.id,content)
  end

  def load_classifier
    cats = categories.all.map(&:id)
    @cl = RubyClassifier::Bayes.new(*cats)
  end

  def save_classifier
    File.open(cl_path,'w'){|f|f.write(Marshal.dump(@cl))}
  end  

  def cl_path
    "#{Rails.root}/data/classifier_#{id}"
end

end


