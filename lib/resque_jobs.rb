# Resque Workers

class BatchClassifier
  @queue = :classifiers
  def self.perform(classifier_ids,document_ids)
    classifiers = Classifier.auto.find(classifier_ids,:include=>:categories)
    Document.where(:id=>document_ids).find_each(:include=>[:body,:classifications]) do |doc|
      classifiers.each{|c|c.classify(doc,true)}
    end
  end
end

class DocumentDownload
  @queue = :documents
  def self.perform(document_id)
    doc = Document.find(document_id)
    doc.get_url_content and doc.get_classifications(true)    
  end
end


class FeedImport
  @queue = :sources
  def self.perform(source_id)
    Source.find(source_id).import_feeds    
  end
end

class ResetSource
  @queue = :sources
  def self.perform(source_id)
    Source.find(source_id).documents.destroy_all
  end
end