class ExternalClassifier < DictionaryClassifier
  alias_attribute :plugin, :regexp
  after_save :save_categories
  @@plugin_path = "#{Rails.root}/plugins/classifiers"
  
  def plugin_list
    Dir["#{@@plugin_path}/*"].map{|i|File.basename(i) if File.executable?(i)}.compact.uniq
  end
  
  def check_plugin
    plugin_list.includes?(plugin)
  end
  
  def classify_batch(documents)
    documents = documents.map(&:id).uniq.compact
    Classification.delete_all( {:document_id=>documents, :classifier_id=>id} )

    pipe = IO.popen("#{@@plugin_path}/#{plugin}",'r+')
    Document.find_each{|doc|pipe.puts relevant_content(doc)}
    pipe.close_write
    values = pipe.readlines.map(&:strip)
    
    return if values.size != documents.size
    
    pos, neg = categories    
    cat_ids = values.map{|i| i == '0' ? neg.id : pos.id}
    
    results = []
    documents.each_with_index do |doc,i|
      results << [doc, cat_ids[i], id, values[i]]
    end
    
    columns = [:document_id, :category_id, :classifier_id, :score]
    Classification.import columns, results, :validate => false
    reset_all_counters
  end
  
  def relevant_content(document)
    super(document).gsub("\n",'')
  end
  
end