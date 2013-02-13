class ClassifiersController < ApplicationController
  before_filter :get_classifiers, :only=>[:index, :show, :new, :edit]
  before_filter :get_classifier, :except => [:index,:new,:create,:classify_all,:codebook]
  before_filter :merge_params
  before_filter :check_admin
  
  def index
    @fullpage = true
    @classifiers = @classifiers.page(params[:page])
  end
  
  def show
  end

  def new
    @classifier = @project.classifiers.build(:parts => %w(title content))
    
    if params[:type] == 'dict'
      @classifier.type = 'DictionaryClassifier'
    elsif params[:type] == 'ext'
      @classifier.type = 'ExternalClassifier'
    else
      @classifier.users << current_user
    end
    @classifier_type = @classifier.type
    2.times{@classifier.categories.build}
  end

  def edit
    @classifier = @project.classifiers.find(params[:id])
    @classifier_type = @classifier.type
    @classifier = @classifier.becomes(Classifier)
  end

  def create
    if params[:classifier][:type] == 'DictionaryClassifier'
      @classifier = DictionaryClassifier.new(params[:classifier])
    elsif params[:classifier][:type] == 'ExternalClassifier'
      @classifier = ExternalClassifier.new(params[:classifier])
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
  # Classifier instance methods
  
  def teach
    redirect_to classifier_path( @classifier.learner || @classifier.create_learner ), :notice => "Learning classifier created for #{@classifier.name}."
  end
  
  def test
    Resque.enqueue(RunReliabilityTest, @classifier.id)
    redirect_to classifier_path(@classifier), :notice => "Reliability test for #{@classifier.name} started in the background."
  end
  
  def classify
    Resque.enqueue(StartBatchClassifier, [@classifier.id])
    redirect_to classifier_path(@classifier), :notice => "Classification for #{@classifier.name} started in the background."
  end
  
  def reset
    Resque.enqueue(ResetClassifier, @classifier.id)
    redirect_to classifier_path(@classifier), :notice => "All classifications for #{@classifier.name} are being deleted in the background."
  end
  
  # Classifier class methods
  
  def classify_all
    Resque.enqueue(StartBatchClassifier, @project.classifiers.auto.all.map(&:id))
    redirect_to classifiers_path, :notice => "Classification for all classifiers started in the background."
  end
  
  def codebook
    @fullpage = true
    @classifiers = @project.classifiers.find(:all)
  end
  
    
  private
  def merge_params
      params[:classifier] = (params[:dictionary_classifier] || params[:learning_classifier] || params[:external_classifier]) unless params[:classifier]
  end
  
  def get_classifier
    @classifier = @project.classifiers.find(params[:id])
  end
  
  def get_classifiers
    @classifiers = @project.classifiers.order(:name)
  end
  
end
