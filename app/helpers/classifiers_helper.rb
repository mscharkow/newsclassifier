module ClassifiersHelper

  def dictionary_classifier_path(id)
    classifier_path(id)
  end
  
  def dictionary_classifiers_path
    classifiers_path
  end
  
  def cltype(classifier)
    classifier.type ? 'automatic': 'manual'
  end
  
  def format_classification(classification)
      cat,pR = classification
      catname = Category.find(cat).name
      prob = Float(pR).round
      "#{catname} (#{prob})"
  end


  
  def classifier_sources(classifier)
    sourcelist = {}
    @project.sources.all.each{|s| sourcelist[s.id]=s.name}
    all = classifier.documents.count(:group=>'source_id')
    cat = classifier.categories.first.documents.count(:group=>'source_id')
    data = cat.map{|i| [sourcelist[i[0]],i[1]]}
    data
  end
  
  def classifier_timeline(classifier)
    data = []
  end
    
    
    

end
