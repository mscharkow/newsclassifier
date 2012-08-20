class ProjectsController < ApplicationController
  skip_before_filter :get_project, :only => [:new, :destroy, :create]
  http_basic_authenticate_with :name => APP_CONFIG['username'], :password => APP_CONFIG['password'], :except=>:show
  
  before_filter :get_stats, :only =>[:show]

  def index
    @projects = Project.all
  end

  def show
    @fullpage = true
    @documents = @project.documents
  end


  def new
    @project = Project.new(:name => 'New Project')
  end
  
  def create
    @project = Project.new(params[:project])
    if @project.save
      redirect_to projects_path, :notice => 'Project created.'
    else
      render :action => "new"
    end
  end

  def edit
    @project = Project.find(params[:id])
  end


  def update
    @project = @project ||= current_user.projects.find(params[:id])
    if @project.update_attributes(params[:project])
      redirect_to(@project) 
    else
      render :action => "edit" 
    end
  end
  
  def destroy
    @project = Project.find(params[:id])
    @project.destroy
    redirect_to projects_path, :notice => 'Project has been deleted.'
  end

  
  private
  
  def get_projects
    @projects = current_user.projects.find(:all, :conditions => ['project_id != ?',@project.id])
  end
  
  def get_stats
    @stats = {}
    @stats[:least_active_source]=@project.sources.first(:order=>'documents_count')
    @stats[:most_active_source]=@project.sources.last(:order=>'documents_count')
    @stats[:least_active_user] = @project.users.all.sort_by{|u|u.documents.size}[0]
    @stats[:most_active_user] = @project.users.all.sort_by{|u|u.documents.size}[-1]
    @stats
  end
end
