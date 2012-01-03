class AddInitialIndices < ActiveRecord::Migration
  def self.up
    add_index "bodies", ["document_id"], :name => "index_bodies_on_document_id"
    add_index "classifications", ["category_id"], :name => "index_classifications_on_category_id"
    add_index "classifications", ["classifier_id"], :name => "index_classifications_on_classifier_id"
    add_index "classifications", ["document_id"], :name => "index_classifications_on_document_id"
    add_index "documents", ["pubdate", "source_id"], :name => "index_documents_on_pubdate_and_source_id"
    add_index "documents", ["source_id", "pubdate"], :name => "index_documents_on_source_id_and_pubdate"
    add_index "documents", ["source_id"], :name => "index_documents_on_source_id"
    add_index "documents", ["url"], :name => "index_documents_on_url"
    add_index "sources", ["auto_update"], :name => "index_sources_on_auto_update"
  end

  def self.down
  end
end
