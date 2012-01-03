module SourcesHelper
  
  def short_source(source)
    truncate(source.name, :limit=>15)
  end
  
  def source_timeline(source)
    data = source.documents.count(:group=>'DATE_FORMAT(pubdate,"%y-%m-%d")')
    data
  end
  
  
  
  def stacked
    out = []
    stats = @sources.collect{|s| [s.documents.size,s.name]}.sort.reverse
    stacked = GoogleChart::BarChart.new('800x120', nil, :vertical, true)
    stacked.data_encoding = :text
    stacked.data "All", stats.collect{|s|s[0]}, '0077CC' 
    stacked.show_legend = false
    stacked.axis :y
    stacked.axis :x, :labels => stats.collect{|s| s[1]}
    stacked.width_spacing_options :bar_width => 40, :bar_spacing => 20, :group_spacing => 10
    stacked.to_url
  end
  
  def sparkline(source, size='180x80')
    return unless source.documents.first
    
    stats = source.stats
    begin
      data = stats.map{|i|i[1]}
      labels = stats.map{|o|o[0][2..-1] if (o[0].to_i).remainder(12)==4}
      mean = data.sum/data.size
      near = 10.power!(data.max.to_s.size-1)
      maxval = data.max + near - (data.max % near)
    rescue
      data.inspect
    end
    
    sparklines = GoogleChart::BarChart.new(size, nil , :vertical,false)
    sparklines.data "Timeline", data, '2299ee'
    sparklines.show_legend = false
    sparklines.max_value maxval
    sparklines.width_spacing_options :bar_width => 5,:bar_spacing => 1, :group_spacing => 1
    sparklines.axis :x, :labels => labels
    sparklines.axis :y, :range=>[0,maxval]
    "<p><img src=\"#{sparklines.to_url}\"/><br/>#{mean} documents per month</p>"
  end
end
