class UsersController < ApplicationController
  before_filter :is_admin?, :only=>[:new, :create, :destroy]
  
  def index
    @fullpage = true
    @users = @project.users.all
  end
    
  def new
  end
  
  def edit
    @user = get_user
  end
  
  def show
   @user = get_user
  end
  
  def update
    if is_admin?
      @user = @project.users.find(params[:id])
    else
      @user = current_user
    end
    @user.update_attributes(params[:user])
    sign_in(@user, :bypass => true)
    redirect_to root_path, :notice => 'User information was updated.'
  end
  
  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = @project.users.new(params[:user])
    @user.save
    if @user.errors.empty?
      @project.users << @user
      redirect_back_or_default(users_path)
      flash[:notice] = "User #{@user.login} was added to the project."
    else
      render :action => 'new'
    end
  end
  
  private
  
  def get_user
    if is_admin?
      User.find_by_id(params[:id])
    else
      current_user
    end
  end

end
