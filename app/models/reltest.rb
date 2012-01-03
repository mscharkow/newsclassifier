class Reltest
  attr_accessor :classifier 
  attr_reader :training_set, :test_set, :problems
  
  def initialize(classifier)
    @problems = []
    @classifier = classifier
    @classifier.reltest = object_id
    cl = {} 
    @classifier.classifications.manual.all.sort_by{rand}.each { |i| cl[i.document_id] = i}
    @all = cl.values
    #@all = cl.uniq.map{|d|@classifier.get_classification_for(d)}
    #@all = @classifier.documents.by_project(@classifier.project).all.uniq.map{|d|@classifier.get_classification_for(d)} # uses every document once
    set_training_set
  end
  
  def set_training_set(spl=0.5)
    all = @all.sort_by{rand}
    splitpoint = (all.size*spl).to_i
    @training_set = all[0..splitpoint]
    @test_set = all[splitpoint+1..all.size]
  end
  
  def train_set(rep=2)
    rep.times do |i|
      classifier.train_batch(@training_set.sort_by{rand}) #.map{|t| classifier.train(t.document,t.category)}
    end
  end
  
  
  def manual(rcode=0)
    #data = classifier.classifications.manual.find(:all,:conditions=>{:document_id,classifier.documents.find_dupes})
    data = classifier.classifications.manual.all
    return false if data.blank?
    users = data.map{|d|d.user_id}.uniq.sort
    docs = data.map{|d|d.document_id}.uniq
    out = {}
    docs.each{|d|out[d]={}}
    data.each{|d|out[d.document_id][d.user_id]=d.category_id}
    csv = []
    out.each{|k,v|csv << users.map{|u|v[u] || 'NA'}}
    rout = "# coders #{users.join(', ')}\nrel <- matrix(c(#{csv.flatten.join(', ')}),nrow=#{users.size}) \n reli(rel)"
    #coeff = (Float(rel_r("#{rout}$statistic").split[1])*100).round/100.0
    coeff = rel_r(rout)
    [rout,coeff]
  end
  
  def run
    classifier.create_classes
    train_set
    cl_res = classifier.classify_batch(@test_set.map{|t|t.document})
    result = []
    @test_set.each_with_index do |t,i|
      result << [t.document.id,t.category.id,cl_res[i].to_i]
    end
    #result = @test_set.map{|t| [ t.document.id, t.category.id, @classifier.classify(t.document)[0]] }
    #@problems << result.map{|t|t[0] if t[1]!=t[2]}.compact.sort.uniq.map{|a|classifier.documents.find(a,:select=>['documents.id'])}
    classifier.destroy_classes
    result.map{|t|[t[1],t[2]]}
    #"kripp.alpha(matrix(c(#{result.flatten.join(',')}),nrow=2))"
  end
  
  def difficult
    # misclassified despite training
    classifier.create_classes
    @training_set = @all
    train_set(1)
    result = @all.collect{|t| [t.document.id,t.category.id, @classifier.classify(t.document)] }
    classifier.destroy_classes
    result.map{|d| d[0] if d[1]!=d[2][0]}.compact.map{|d| classifier.documents.find(d[0],:select=>['documents.id'])}
    #"kripp.alpha(matrix(c(#{result.flatten.join(',')}),nrow=2))"
  end
  
  def k_fold(k=10,rcode=0)
    folds = @all.sort_by{rand}
    j = (@all.size/Float(k)).ceil
    out = []
    k.times do |i|
      @training_set = @test_set = []
      @test_set = folds[i*j..(i+1)*j-1]
      @training_set = folds-@test_set
      res = run
      #puts res.map{|d|d[0].document.title if d[1] != d[2]}
      out << res
      #puts "kripp.alpha(matrix(c(#{res.flatten.join(',')}),nrow=2))"
      #@test.set.each{|t|folds << t}
    end
    rout="rel <- matrix(c(#{out.flatten.join(', ')}),nrow=2)\n reli(rel)"
    #coeff = (Float(rel_r("#{rout}$statistic").split[1])*100).round/100.0
    coeff = rel_r(rout)
    [rout,coeff]
  end
  
  
  def rel_r(result)
    puts result
    r = IO.popen('R --slave ','w+')
    r.write("source('bin/reli.r')\n#{result}")
    r.close_write
    c = r.read
    r.close
    c.gsub(/(\n)+/,'').split[1..-1]
  end
  
  #class methods
  def self.rep_k_fold(c,optmask=0,k=2,j=2)
    res = []
    k.times do |x|
      r = Reltest.new(c)
      c.options_mask = optmask
      j.times do |y|
        row = [c.id, c.name, optmask, c.options(:raw),c.options(:stop),c.options(:stem),c.options(:short),c.options(:notitle),r.object_id, Time.now, y, r.k_fold[1] ]
        res << row
        ff = File.open('/tmp/output.csv','a')
        ff.write("#{row.join(',')}\n" )
        ff.close
      end
    end
    res
  end
end

class Array
  def find_dupes
    uniq.select{ |e| (self-[e]).size < self.size - 1 }
  end
end

