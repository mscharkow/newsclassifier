class LearningClassifier < Classifier
  validates_presence_of :teacher_id
  belongs_to :teacher, :class_name=>'Classifier', :inverse_of=>:learner
  before_validation :set_defaults
  after_create :setup_categories
  
  def set_defaults
    self.project = teacher.project
    self.name = "#{teacher.name} Learning"
    self.parts = %w(title content)
  end
  
  def setup_categories
    teacher.categories.each do |cat|
      self.categories.create(:value=>cat.id,:name=>"#{cat.name} Learning")
    end
  end
  
  # Reliability tests
  
  #TODO 
  def k_fold_cv(k=10)
 
    cat_ids = teacher.classifications.map(&:category_id)
    cat_ids.zip(cat_ids)
  end
  
  def accuracy
    agreement(k_fold_cv)
  end
  
  # Supervised Classification

  def classify(document,permanent=false)
    if not permanent
      val = bayes_classifier.classify(relevant_content(document))
    else
      document.categories << categories.find_by_value(val)
    end
  end

  def classify_batch(documents,permanent=false)
    documents.map{|doc|bayes_classifier.classify(relevant_content(doc),permanent)}
  end

  def scores(document)
    bayes_classifier.cat_scores(relevant_content(document)) 
  end
  
  def train_on(classification)
    if classification.category.id != classify(classification.document)
      bayes_classifier.train(classification.category.id,relevant_content(classification.document))
      bayes_classifier.save_state
    end
  end
  
  def bayes_classifier
    @bayes ||= create_bayes
  end
  
  def create_bayes
    store = StuffClassifier::FileStorage.new(Rails.root+"data/classifier_#{id}")
    @bayes = StuffClassifier::TfIdf.new(id, :stemming => false,:storage => store)
    categories.each{|cat| @bayes.train(cat.value,'')}
    if @bayes.training_count <= categories.size
      teacher.classifications.includes(:category,:document=>:body).sort_by{rand}.each{|cl|train_on(cl)}
    end
    @bayes
  end  
  
end