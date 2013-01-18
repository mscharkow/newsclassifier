class UsersController < ApplicationController
  before_filter :check_admin, :only=>[:new, :create, :destroy]
  before_filter :get_user, :except=>[:new, :index]
  
  def index
    @fullpage = true
    @users = @project.users.all
  end
    
  def new
    @user = User.new
  end
  
  def edit
    @user = get_user
  end
  
  def show
   @user = get_user
  end
  
  def update
    @user = get_user
    @user.update_attributes(params[:user])
    sign_in(@user, :bypass => true)
    redirect_to root_path, :notice => 'User information was updated.'
  end
  
  def create
    @user = @project.users.new(params[:user])
    @user.save
    if @user.errors.empty?
      @project.users << @user
      redirect_to users_path, :notice => "User #{@user.email} was added to the project."
    else
      render :action => 'new'
    end
  end
  
  def destroy
    if @user.admin?
      redirect_to users_path, :notice=> "Admin #{@user.email} cannot be deleted."
    else
      @user.destroy
      redirect_to users_path, :notice=> "User #{@user.email} was removed from the project."
    end
  end
  
  private
  
  def get_user
    if is_admin?
      @user = @project.users.find_by_id(params[:id])
    else
      @user = current_user
    end
  end

end
