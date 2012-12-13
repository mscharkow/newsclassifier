class LearningClassifier < Classifier
  validates_presence_of :teacher_id
  belongs_to :teacher, :class_name=>'Classifier'
  before_validation :set_defaults
  after_create :setup_categories
  
  def set_defaults
    self.project = teacher.project
    self.name = "#{teacher.name} Learning"
    self.parts = %w(title content)
  end
  
  def setup_categories
    teacher.categories.each do |cat|
      self.categories.create(:value=>cat.id,:name=>"#{cat.name}")
    end
  end
    
  def reset
    classifications.destroy_all
    File.delete(storage_path)
  end
  
  # Reliability tests
  
  def k_fold_cv(k=5)
    output = []
    set = teacher.classifications.includes(:category,:document).sort_by{rand}[0..500]
    return [] if set.size < k
    set.in_groups_of(set.size/k) do |fold|
      fold = fold.uniq.compact
      bayes = StuffClassifier::TfIdf.new(id,:stemming => false)
      teacher.categories.each{|cat| bayes.train(cat.id,relevant_content(cat.documents.first))}
      train = (set-fold).each do |cl| 
        bayes.train(cl.category_id,relevant_content(cl.document)) if needs_training?(bayes,cl)
      end
      res = fold.map { |cl| bayes.classify(relevant_content(cl.document)) }
      output << res
    end
    set.map{|cl|cl.category_id}.zip(output.flatten)
  end
    
  def reliability_metrics
    tp, fn, fp, tn =  confusion_matrix(reliability).map{|i|i[1]}
    precision = 1.0*tp/(tp+fp) rescue 0
    recall = 1.0*tp/(tp+fn) rescue 0
    f = 2.0 * (precision*recall)/(precision+recall)
    {:precision=>precision.round(2), :recall=>recall.round(2), :f=>f.round(2)}
  end
 
  def set_reliability
    update_attribute(:reliability,k_fold_cv)
  end
  
  # Supervised Classification

  def classify(document,permanent=false)
    val = bayes_classifier.classify(relevant_content(document))
    category = categories.find_by_value(val)
    if permanent && category
      document.categories << category
    end
  end

  def classify_batch(documents)
    documents.each{ |doc| classify(doc, true)}
  end
  
  def classify_all
    project.documents.find_in_batches(:batch_size=>1000,:include=>:body){ |batch| classify_batch(batch) }
  end
  
  def train_on(classification)
    if needs_training?(bayes_classifier, classification)
      bayes_classifier.train(classification.category.id,relevant_content(classification.document))
      bayes_classifier.save_state
    end
  end
  
  
  # Internal stuff
  
  def scores(document)
    bayes_classifier.cat_scores(relevant_content(document)) 
  end
  
  def needs_training?(bayes, classification)
    threshold = 2
    scores =  bayes.cat_scores(relevant_content(classification.document))
    classification.category_id != scores[0][0] || (scores[0][1]/(scores[1][1])) < threshold
  end
  

  
  def bayes_classifier
    @bayes ||= create_bayes
  end
  
  def create_bayes
    store = StuffClassifier::FileStorage.new(storage_path)
    @bayes = StuffClassifier::TfIdf.new(id, :stemming => false, :storage => store)
    categories.each{|cat| @bayes.train(cat.value,'')}
    if @bayes.training_count <= categories.size
      training_set = teacher.classifications.includes(:category,:document=>:body).sort_by{rand}
      training_set = training_set[0..training_set.size/2] if teacher.type == 'DictionaryClassifier'
      training_set.each{ |cl|train_on(cl) }
    end
    @bayes
  end
  
  def storage_path
    "#{Rails.root}/data/classifier_#{id}"
  end 
end