class DocumentsController < ApplicationController
  before_filter :get_document, :except=>[:index,:new, :create]
  before_filter :next_document, :only=>[:show,:index]
  skip_before_filter :is_admin?
  
  #caches_action :index, :cache_path => Proc.new {|c| c.request.url }

  
  def show
    @classifiers = current_user.classifiers.manual.find_all_by_project_id(@project, :include=>:categories)
    @parts = @classifiers.map{|c|c.parts}.flatten.uniq 
    @parts = %w(title content) if @parts.blank?
    @classifiers.each do |classifier|
      unless  @document.classifications.scoped_by_user_id(current_user).collect{|c| c.classifier_id}.include?(classifier.id)
        @document.classifications.build(:classifier=>classifier,:user=>current_user) 
      end
    end
  end
  

  def index
    @fullpage = true

    if params[:source]
      docs = Source.find(params[:source]).documents
    elsif params[:category]
      docs = Category.find(params[:category]).documents
    else
      docs = @project.documents.includes(:source)
    end
    
    if request.format == 'html'
      @documents = docs.order('pubdate DESC').page(params[:page])
    elsif request.format == 'json'
      @documents = docs.count(:group=>'DATE_FORMAT(pubdate,"%Y-%m-%d")').map{|k,v|["#{k} 00:00PM",v]}.to_json
    else
      @documents = docs.order('pubdate DESC')
    end
    
    respond_to do |format|
      format.html # index.html.erb
      #format.csv {@project.csv and send_file("/tmp/documents_#{@project.id}.csv", :type=>"text/csv", :x_sendfile=>true) unless params[:links] }
      format.csv {render :text=>@project.csv unless params[:links] }
      format.text {render :text => @documents.map(&:title).join("\n")}
      format.xml  {render :xml => @documents }
      format.json {render :json => @documents}
    end
  end


  def update
      params[:classifications].each do |c|
        if c[:id] && cl = @document.classifications.find_by_id_and_user_id(c[:id],current_user) # existing classification?
          if c[:category_id].blank? #empty category, delete
            cl.destroy
          else
           cl.update_attributes(:category_id=>c[:category_id])
          end
        elsif cat = Category.find_by_classifier_id_and_id(c[:classifier_id],c[:category_id]) # new classification
          @document.classifications.create!(:user=>current_user,:category=>cat)
          flash[:notice] = 'Created new classification'
        end
      end
      
      if @next = next_document
        redirect_to document_path(@next)
      else
        redirect_to documents_path
      end
  end

  
  private
  
  def get_document
     @document = @project.documents.find(params[:id])
  end
  
  
  def next_document
    session[:doclist] =  @project.documents.for_user(User.first).all(:select=>:id).sort_by{rand}[0..19] if session[:doclist].blank?
    @next = session[:doclist].pop
  end
  

  
end
