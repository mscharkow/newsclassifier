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
  
  has_one :learner, :class_name=>'LearningClassifier', :foreign_key => 'teacher_id'
  
  serialize :parts
  serialize :reliability

  scope :manual, where(:type=>nil)
  scope :auto, where(:type=>'DictionaryClassifier')
    
  validates_presence_of :project_id, :message => "must be set."
  validates_presence_of :name, :message => "can't be blank"
  validates_presence_of :parts, :message => "can't be blank"
  validates_uniqueness_of :name, :scope=>:project_id

  def variable_name
    name.gsub(/\W+/,'_').downcase
  end
  
  # Parts definitions and methods
  before_save :cleanup_parts
  
  def default_parts
     %w(title summary content raw_content url)
  end
  
  def cleanup_parts
    self.parts = parts.map{|p|p if default_parts.include?(p)}.compact.uniq
  end

  def relevant_content(document)
    Rails.cache.fetch([document.cache_key, self.parts]) { parts.map{|p| document.send(p)}.join("\n") }
  end
  
  
  # Select from multiple classifications (FIXME after LearningClassifier transition)
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
  
  def reliability_score
    agreement(reliability) if reliability && reliability.size > 20
  end
  
  def set_reliability
    false
  end

  def confusion_matrix(data)
    data.group_by{|b|b}.map{|k,v| [k,v.size]}.sort if data
  end

  def agreement(data)
    (data.map{|i|i.uniq.size == 1 ? 1:0}.inject(:+).to_f/data.size).round(2)
  end

end


