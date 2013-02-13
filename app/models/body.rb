class Body < ActiveRecord::Base
  belongs_to :document, :touch => true
  before_save :set_content
  before_save :clean_content

  def set_content
    if content.blank? && raw_content?
      self.content = extract_text(raw_content) 
    end
  end
  
  def clean_content
    self.raw_content = raw_content.split.join(' ').strip if raw_content
    self.summary = summary.split.join(' ').strip if summary
  end
  
  
  # TODO: Refactor for filter plugins
  def extract_text(text=raw_content)
    return '' if text.blank?
    html = Nokogiri::HTML(text)
    %w(script style form .comments meta).each{|i| html.search(i).remove}
        
    if element = document.source.metadata[:filter]
     filtered = html.at(element) rescue nil
    end
    
    content = (filtered || html).inner_html
    
    bte = IO.popen("#{Rails.root}/plugins/filters/bte",'w+')
    bte.write(content)
    bte.close_write
    c = bte.read
    bte.close
    c.gsub(/(\n)+/,"\n\n").strip
  end
  
  def as_json(options={})
    super :only => [:summary, :content, :raw_content]
  end
end