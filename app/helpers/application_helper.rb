module ApplicationHelper
  def abutton_to(text,path,options={})
    options = {method:'get',class:'',icon:nil}.merge(options)
    
    text = "<i class='icon-#{options[:icon]}'></i> ".html_safe+text if options[:icon]
    link_to text, path, {:method=>options[:method],:class=>"btn #{options[:style]}"}
  end
  
  def document_timeline(docs)
    data = docs.count(:group=>'DATE_FORMAT(pubdate,"%y-%m-%d")').map{|k,v|[k,v]}.to_json
  end
  
  def version_info
    `git log -1 | head -n 3`
  end
end
