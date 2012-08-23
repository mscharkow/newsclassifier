class DictionaryClassifier < Classifier
  validates_presence_of :regexp
  after_save :save_categories
  
  def reg
    if self.regexp[0] != '/'
      Regexp.new(regexp,true)
    else
      eval(regexp)
    end
  end
  
  def save_categories
    if self.categories.size < 2
      categories.create!(:value=>'1',:name=>'True', :description=>'Matches string.')
      categories.create!(:value=>'0',:name=>'False', :description=>'Does not match string.')
    end 
  end
    
  def classify(document,permanent=false)
    result = relevant_content(document).scan(reg)
    if result.size > 0
      res = {:document=>document,
             :category=>self.categories[0],:score=>result.size} #true
    else
      res = {:document=>document,
             :category=>self.categories[1],:score=>0} # false
    end
    if permanent
      if cl = document.classifications.select{|i|i.classifier_id==id}[0] 
        cl.update_attributes(res) if cl.score != res[:score]
      else
         cl = Classification.find_or_create_by_document_id_and_classifier_id(document.id,id)
         cl.update_attributes(res)
      end
    else
      cl = classifications.build(res)
    end
    cl
  end
  
  def classify_batch(documents)
    classifications.where({document_id:documents}).destroy_all
    results = []
    results << Document.where({id:documents}).title_matches(regexp) if parts.include?('title')
    results << Document.where({id:documents}).url_matches(regexp) if parts.include?('url')
    results << Document.where({id:documents}).summary_matches(regexp) if parts.include?('summary')
    results << Document.where({id:documents}).content_matches(regexp) if parts.include?('content')
    results << Document.where({id:documents}).raw_content_matches(regexp) if parts.include?('raw_content')
    results = results.flatten.uniq
    puts results.count
    pos, neg = categories
    pos.documents << results
    neg.documents << documents-results
    Classifier.reset_counters self.id, :classifications
    Category.reset_counters pos.id, :classifications
    Category.reset_counters neg.id, :classifications
  end
  
  def terms_for(document)
    relevant_content(document).scan(reg)
  end
  
  def classify_all
    project.documents.find_each{|d|self.classify(d)}
  end
end
