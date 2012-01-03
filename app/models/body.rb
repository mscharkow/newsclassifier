class Body < ActiveRecord::Base
  belongs_to :document

  def sanitize_content
    coder = HTMLEntities.new
    self.raw_content = coder.decode(raw_content)
    self.summary = coder.decode(summary)
  end
  
  def get_content
    if content?
      content
    elsif raw_content == '404' || raw_content.blank?
      extract_text(summary)
    else
      extract_text(raw_content)
    end
  end
  
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
    return c.gsub(/(\n)+/,"\n\n")
  end
  
end