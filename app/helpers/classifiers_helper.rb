module ClassifiersHelper

  def dictionary_classifier_path(id)
    classifier_path(id)
  end
  
  def dictionary_classifiers_path
    classifiers_path
  end
  
  def classifier_type(classifier)
    if classifier.type
      classifier.type.gsub('Classifier','')
    else
      'Manual'
    end
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
  
  def reliability_plot(classifier)
    return '' if classifier.type == 'DictionaryClassifier'
    rel = classifier.reliability_metrics[:f]
    status = 'success'
    status = 'warning' if rel < 0.8 and rel >= 0.5
    status = 'danger' if rel < 0.5
    "<div class='reli_plot progress progress-#{status} progress-striped'><div class='bar' style='width: #{rel*100}%'>#{rel}</div></div>".html_safe
  end
    
  def category_plot(classifier)
    return '' unless classifier.type == 'DictionaryClassifier'
    width = classifier.categories.first.percent.round
    "<div class='category_plot progress progress-striped'><div class='bar' style='width: #{width}%'>#{width}</div></div>".html_safe
  end
    
  def confusion_table(classifier)
    r = classifier.coincidence_matrix.map{|i|i[1]}
    "<table><tr><td>#{r[0]}</td><td>#{r[2]}</td></tr><tr><td>#{r[1]}</td><td>#{r[3]}</td></tr></table>".html_safe
  end
  
  def reli_rcode(classifier)
    out = classifier.confusion_matrix(classifier.reliability).map {|i|"rep(c(#{i[0].join(',')}),#{i[1]})"}
    "library(irr)\ndata = matrix(c(#{out.join(',')}),nrow=2)\nagree(t(data))\nkripp.alpha(data)"
  end

end
