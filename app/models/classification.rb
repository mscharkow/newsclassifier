class Classification < ActiveRecord::Base
  belongs_to :document #, :counter_cache => true
  belongs_to :category, :counter_cache => true
  belongs_to :user
  belongs_to :classifier,:counter_cache => true
  
  #named_scope :by_project, lambda { |project| { :conditions => ['classifier_id in (?) and document_id in(?)', project.classifiers,project.documents(:select=>:id)] }}
  scope :auto, where(:user_id => nil)
  scope :manual, where('user_id > 0')
 
  validates_presence_of :document_id
  validates_presence_of :category_id
  
  #validates_uniqueness_of :classifier_id, :scope=>[:document_id, :user_id] TODO: find out if it's necessary
  
  before_save :set_classifier
  #after_create :train
  
  def set_classifier
    self.classifier = category.classifier unless classifier_id
  end
  
  def train
    return if user_id.blank?
    classifier.train(document,category)
  end
  
  def test
    classifier.classify(document)[0]  == category.id
  end
  
  def code
    score || category.val
  end
  
end
