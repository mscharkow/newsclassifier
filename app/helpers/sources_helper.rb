module SourcesHelper
  
  def short_source(source,limit=20)
    if source.name.size < limit
      source.name
    else
      source.name[0..limit]+'...'
    end
  end
  
  def yesno(condition)
    if condition
      'Yes'
    else
      'No'
    end
  end
  
end
