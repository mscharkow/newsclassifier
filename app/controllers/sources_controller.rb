class SourcesController < ApplicationController
  before_filter :get_sources, :only=>[:index, :show, :new, :edit]
  before_filter :get_source, :except=>[:index,:new,:create,:import_all]
  
  def index
    @fullpage = true
    @sources = @sources.page(params[:page]) if request.format == 'html'
    respond_to do |format|
      format.html# index.html.erb
      format.csv
    end
  end

  def show
  end

  def new
    @source = Source.new
    @source.clean_metadata
  end

  def edit
  end

  def create
    @source = Source.new(params[:source])
    @source.project = @project
    @source.create_from_url
    if @source.save
      redirect_to sources_path, :notice => "Source #{@source.name} was successfully created."
    elsif params[:source][:site_url]
      redirect_to @source, :alert=>"Source #{@source.site_url} could not be created."
    else 
      render :action => "new"
    end
  end

  def update
    if @source.update_attributes(params[:source])
        flash[:notice] = "Source #{@source.name} was successfully updated."
        redirect_to(sources_path)
    else
      render :action => "edit"
    end
  end

  def destroy
    @source.destroy and flash[:notice] = "Source #{@source.name} was deleted."
    redirect_to(sources_url)
  end
  
  def reset
    Resque.enqueue(ResetSource,@source.id)
    flash[:info] = "All documents from #{@source.name} are being deleted. This may take a minute."
    redirect_to(sources_url)
  end
  
  def import 
    Resque.enqueue(FeedImport, @source.id)
    flash[:info] = "Import from #{@source.name} started. This may take a minute."
    redirect_to(sources_url)
  end
  
  def import_all
    @project.sources.find_each{|s|Resque.enqueue(FeedImport, s.id)}
    flash[:info] = "Import for all sources started. This may take a while."
    redirect_to(sources_url)
  end
  
  private
  
  def get_source
    @source = @project.sources.find(params[:id])
  end
  
  def get_sources
    @sources = @project.sources.order(:name)
  end
    
end
