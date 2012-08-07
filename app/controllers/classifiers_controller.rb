class ClassifiersController < ApplicationController
  before_filter :is_admin?
  before_filter :get_classifier, :except => [:index,:new,:create,:classify_all,:codebook]
  before_filter :merge_params
  
  def index
    @fullpage = true
    @classifiers = @project.classifiers.find(:all,:order => :name)
  end
  
  def show
    @manual = @classifier.manual_reliability
  end

  def new
    @classifier = Classifier.new(:parts => %w(title content))
    if params[:type] == 'dict'
      @classifier.type = 'DictionaryClassifier'
    else
      @classifier.users << current_user
    end
    2.times{@classifier.categories.build}
  end

  def edit
    @classifier = @project.classifiers.find(params[:id]).becomes(Classifier)
  end

  def create
    if params[:classifier][:type] == 'DictionaryClassifier'
      @classifier = DictionaryClassifier.new(params[:classifier])
    else
      @classifier = @project.classifiers.new(params[:classifier])
    end
    @classifier.project = @project
    if @classifier.save
      redirect_to classifiers_path, :notice => 'Classifier was successfully created.'
    else
      render :action => "new"
    end
  end

  def update
    if @classifier.update_attributes(params[:classifier])
      redirect_to classifier_path(@classifier), :notice => 'Classifier was successfully updated.'
    else
      render :action => "edit"
    end
  end

  def destroy
    @classifier.destroy
    redirect_to classifiers_path, :notice => "Classifier #{@classifier.name} was deleted."
  end
  
  # Extra actions
  
  def codebook
    @fullpage = true
    @classifiers = @project.classifiers.find(:all)
  end
  
  def classify
    @project.documents.find_in_batches(:select=>:id) do |docs| 
      Resque.enqueue(BatchClassifier, [@classifier.id], docs.map(&:id))
    end
    redirect_to classifiers_path, :notice => "Classification for #{@classifier.name} started. This may take a while."
  end
  
  def classify_all
    @project.documents.find_in_batches(:select=>:id) do |docs| 
      Resque.enqueue(BatchClassifier, @project.classifiers.auto.all.map(&:id), docs.map(&:id))
    end
    redirect_to classifiers_path, :notice => "Classification for all classifiers started. This may take a long time."
  end
  
  private
  def merge_params
      params[:classifier] = params[:dictionary_classifier] unless params[:classifier]
  end
  
  def get_classifier
    @classifier = @project.classifiers.find(params[:id])
  end
end
