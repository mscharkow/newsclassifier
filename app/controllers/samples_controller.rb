class SamplesController < ApplicationController
  def index
    @fullpage = true
    @samples = @project.samples.all
  end

  def show
    @sample = @project.samples.find(params[:id])
  end

  def new
    @sample = Sample.new
  end

  def edit
    @sample = @project.samples.find(params[:id])
  end

  def create
    @sample = Sample.new(params[:sample])
    @sample.project = @project
    if @sample.save
       redirect_to samples_path, :notice=>'Sample was successfully created.'
    else
      render :action => "new" 
    end
  end

  def update
    @sample = @project.samples.find(params[:id])
    if @sample.update_attributes(params[:sample])
      redirect_to samples_path, :notice => 'Sample was successfully updated.'
    else
      render :action => "edit"
    end
  end

  def destroy
    @sample = @project.samples.find(params[:id])
    @sample.destroy
    redirect_to samples_path
  end
  
  
  def activate
    @sample = @project.samples.find(params[:id])
    if @sample.active?
      @sample.deactivate
    else
      @sample.activate
    end
    session[:doclist] = []
    redirect_to samples_path
  end
  
end
