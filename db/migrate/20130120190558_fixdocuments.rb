class Fixdocuments < ActiveRecord::Migration
  def up
    remove_index :documents, :column => :url
    change_column :documents, :title, :text
    change_column :documents, :url, :text
    add_index "documents", ["url"], :name => "index_documents_on_url", :length=>255
  end
  def down
    change_column :documents, :title, :string
    change_column :documents, :url, :string 
  end
end
