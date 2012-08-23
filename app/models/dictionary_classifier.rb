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
    documents = documents.map(&:id).compact.uniq
    Classification.delete_all({document_id:documents,classifier_id:id})
    
    results = get_matching_documents(documents)
    puts documents.size, results.size, (documents-results).size
    pos, neg = categories
    
    columns = [:document_id,:category_id,:classifier_id]
    cl_pos = results.map{|i| [i,pos.id,self.id]}
    cl_neg = (documents-results).map{|i| [i,neg.id,self.id]}
    Classification.import columns, cl_pos+cl_neg, :validate => false


    #pos.documents << results
    #neg.documents << documents-results
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
  
  private
  
  def get_matching_documents(documents)
    doc_set = Document.where({id:documents})
    results = []
    if regexp[0] == '%'
      terms = regexp.gsub('%','').split("\n").map{|i|"%#{i}%" unless i.blank?}.compact
      results << doc_set.where{title.like_any terms}.pluck('documents.id') if parts.include?('title')
      results << doc_set.where{url.like_any terms}.pluck('documents.id') if parts.include?('url')
      results << doc_set.joins(:body).where{body.summary.like_any terms}.pluck('documents.id') if parts.include?('summary')
      results << doc_set.joins(:body).where{body.content.like_any terms}.pluck('documents.id') if parts.include?('content')
      results << doc_set.joins(:body).where{body.raw_content.like_any terms}.pluck('documents.id') if parts.include?('raw_content')
    else
      results << doc_set.title_matches(regexp).pluck('documents.id') if parts.include?('title')
      results << doc_set.url_matches(regexp).pluck('documents.id') if parts.include?('url')
      results << doc_set.summary_matches(regexp).pluck('documents.id') if parts.include?('summary')
      results << doc_set.content_matches(regexp).pluck('documents.id') if parts.include?('content')
      results << doc_set.raw_content_matches(regexp).pluck('documents.id') if parts.include?('raw_content')
    end
    results.flatten.compact.uniq
  end
  
  
end
