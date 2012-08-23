# Resque Workers

class BatchClassifier
  @queue = :classifiers
  def self.perform(classifier_ids)
    classifiers = Classifier.auto.find(classifier_ids,:include=>:categories)
    classifiers.first.project.documents.find_in_batches(:batch_size=>5000,:select=>:id) do |docs|
      classifiers.each{|c|c.classify_batch(docs)}
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