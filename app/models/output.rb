class Output
  def initialize(project)
    @project = project
  end
    
  def hlink(document,suffix)
    link ="articles/#{document.gf_id}.#{suffix}"
    "=HYPERLINK(\"#{link}\")"
  end
  
  def create_hash(classifiers,documents)
    cl = Classification.manual.find_all_by_classifier_id_and_document_id(classifiers,documents,:include=>:category)
    cla = Classification.auto.find_all_by_classifier_id_and_document_id(classifiers,documents,:include=>:category)
    
    ha = {}
    cla.each{|c| ha[ [c.classifier_id,c.document_id] ] = c.code}
    cl.each{|c| ha[ [c.classifier_id,c.document_id] ] = c.code}
    ha
  end
    
  def to_csv(conditions=nil)
    classifiers = @project.classifiers
    classifier_list = classifiers.map(&:variable_name)
    std = %w(id url title pubdate year month day dayofweek hour minute createdate source links ulinks)
    header = [std, classifier_list].flatten.join(';')
    out = []
    out << header
    Document.by_project(@project).find_in_batches(:batch_size=>5000,:conditions=>conditions,:include=>[:source]) do | documents|
      key = [classifier_list.join,documents.first, documents.last, documents.first.classifications.last,documents.last.classifications.last] || Time.now.to_s
      out << Rails.cache.fetch(key) do 
        ha = self.create_hash(classifiers,documents)
        documents.map {|d| [d.id, d.clean(d.url), d.clean(d.title), d.pubdate.strftime('%Y-%m-%d-%H-%M;%Y;%m;%d;%a;%H;%M'), d.created_at.strftime('%Y-%m-%d-%H-%M'), d.clean(d.source.name), d.links.size, d.unique_links.size, classifiers.map{|c| ha[ [c.id,d.id] ] rescue 'NA' }].flatten.join(';')}.join("\n")+"\n"
      end
    end
    out.join("\n")
  end
  
end
