class Body < ActiveRecord::Base
  belongs_to :document, :touch => true
  before_save :set_content
  before_save :clean_content

  def set_content
     self.content = extract_text(raw_content) if content.blank? && raw_content
  end
  
  def clean_content
    self.raw_content = raw_content.split.join(' ').strip if raw_content
    self.summary = summary.split.join(' ').strip if summary
  end
  
  
  # TODO: Refactor for filter plugins
  def extract_text(text=raw_content)
    return '' if text.blank?
    html = Nokogiri::HTML(text)
    %w(script style form .comments).each{|i|html.search(i).remove}
    element = document.source.metadata[:filter]
    unless element.nil?
     filtered = html.at(element).inner_html rescue nil
    end
    content = filtered || html
    bte = IO.popen('./bin/bte','w+')
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