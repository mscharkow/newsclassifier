class Sample < ActiveRecord::Base
  belongs_to :project
  serialize :items
  
  attr_accessor :num_items
  validates_presence_of :project_id
  after_create :set_documents
  
  #named_scope :active, :conditions =>{:active=>true}


  def validate
    errors.add :num_items, "must be smaller than document number (#{project.documents.count})" if  num_items.to_i > Document.where(['source_id in (?)',project.sources]).count
  end
  
  def set_documents(limit=false)
    limit ||= num_items.to_i || 10
    update_attribute(:items,Document.where(['source_id in (?)',project.sources]).all(:select=>:id).sort_by{rand}[1..limit].map(&:id))
  end
    
  def activate
    project.samples.each {|s|s.deactivate}
    self.update_attribute(:active,true)
  end
  
  def deactivate
    self.update_attribute(:active,false)
  end
  
end
