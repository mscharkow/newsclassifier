module DocumentsHelper
  
  def category_select(classifiers)
    arr = {}
    classifiers.each do |cl|
      arr[cl.name] = cl.categories.collect{|cat| [cat.name,cat.id]}
    end
    arr.inspect
  end
  
  def categories_as_csv(classifiers,document)
    classifiers.collect{|c|c.get_classification_for(document).code}.join(',')
    #cats = document.cats_for_classifiers(classifiers)
    #out = []
    #a = classifiers.collect{|c|c.id}
    #a.each do |cl|
    #  out << cats[cl]
    #end 
    #','+out.join(',')
  end
  
end
