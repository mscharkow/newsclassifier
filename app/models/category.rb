class Category < ActiveRecord::Base
  attr_accessor :should_destroy
  belongs_to :classifier, :counter_cache => true
  has_many :classifications, :dependent => :destroy
  has_many :documents, :through => :classifications

  validates_presence_of :classifier_id, :on=>:update

  def should_destroy?
    should_destroy.to_i == 1
  end

  def percent
    return 0 if classifier.classifications.size == 0
    classifications.size*100.0/classifier.classifications.size
  end

  def val
    value || id
  end
end
