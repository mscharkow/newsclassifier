# Resque Workers

class StartBatchClassifier
  @queue = :classifiers
  def self.perform(classifier_ids)
    classifiers = Classifier.auto.find(classifier_ids,:include=>:categories)
    classifiers.first.project.documents.find_in_batches(:batch_size=>5000,:select=>:id) do |docs|
       classifiers.each do | cl| 
         Resque.enqueue(BatchClassifier, cl.id, docs.map(&:id))
       end
    end
  end
end

class BatchClassifier
  @queue = :classifiers
  def self.perform(classifier_id,documents_ids)
    classifier = Classifier.find(classifier_id)
    docs = Document.where({id:documents_ids})
    classifier.classify_batch(docs)
  end
end

class DocumentDownload
  @queue = :documents
  def self.perform(document_id)
    doc = Document.find(document_id)
    doc.get_url_content   
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

class ResetClassifier
  @queue = :classifiers
  def self.perform(classifier_id)
    Classifier.find(classifier_id).reset
  end
end

class RunReliabilityTest
  @queue = :classifiers
  def self.perform(classifier_id)
    Classifier.find(classifier_id).set_reliability
  end
  
end