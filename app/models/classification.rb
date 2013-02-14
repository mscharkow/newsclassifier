class Classification < ActiveRecord::Base
  belongs_to :document #, :counter_cache => true
  belongs_to :category, :counter_cache => true
  belongs_to :user
  belongs_to :classifier,:counter_cache => true
  
  scope :auto, where(:user_id => nil)
  scope :manual, where('user_id > 0')
 
  validates_presence_of :document_id
  validates_presence_of :category_id
  
  #validates_uniqueness_of :classifier_id, :scope=>[:document_id, :user_id] TODO: find out if it's necessary
  
  before_save :set_classifier
  
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
