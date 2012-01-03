module ApplicationHelper
  def abutton_to(text,path,style='',method='get')
    link_to text, path, {:method=>method,:class=>"abutton #{style}"}
  end
  
  def document_timeline(docs)
    data = docs.count(:group=>'DATE_FORMAT(pubdate,"%y-%m-%d")').map{|k,v|[k,v]}.to_json
  end
end
