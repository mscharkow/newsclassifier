class DictionaryClassifier < Classifier
  validates_presence_of :regexp, :unless => Proc.new {|r| r.is_a? ExternalClassifier}
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
      categories.create!(:value=>'1',:name=>'positive', :description=>'Document matches pattern.')
      categories.create!(:value=>'0',:name=>'negative', :description=>'Document does not match pattern.')
    end 
  end
  
  
  # FIXME REFACTOR  
  def classify(document)
    classify_batch [document] and classifications.find_by_document_id(document.id).category
  end
  
  def classify_batch(documents)
    documents = documents.map(&:id).uniq.compact
    Classification.delete_all( {:document_id=>documents, :classifier_id=>id} )
    
    results = get_matching_documents(documents)
    pos, neg = categories
    
    columns = [:document_id, :category_id, :classifier_id]
    cl_pos = results.map{|i| [i, pos.id, id]}
    cl_neg = (documents - results).map{|i| [i, neg.id, id]}
    Classification.import columns, cl_pos + cl_neg, :validate => false

    reset_all_counters
  end
  
  def terms_for(document)
    relevant_content(document).scan(reg)
  end
  
  def classify_all
    project.documents.find_in_batches(:batch_size=>5000, :select=>:id){|batch| classify_batch(batch) }
  end
  
  def reset
     Classification.delete_all( {:classifier_id=>id} )
     reset_all_counters
  end
  
  private
  
  def get_matching_documents(documents)
    doc_set = Document.where({id:documents})
    results = []
    if regexp[0] == '%'
      terms = regexp.gsub('%','').split(/\r?\n/).map{|i|"%#{i}%" unless i.blank?}.compact
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
