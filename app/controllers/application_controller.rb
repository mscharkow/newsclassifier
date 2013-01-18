class ApplicationController < ActionController::Base
  protect_from_forgery
  helper :all # include all helpers, all the time
  helper_method :is_admin?
  before_filter :get_project
  before_filter :authenticate_user!


  protected
  def get_project
    subdomain = request.subdomains.first
    unless @project = Project.where(:permalink=>subdomain).first || Project.where(:permalink=>'demo').first
      raise ActionController::RoutingError.new("Error! Project #{subdomain} does not exist.")
      false
    end
  end

  def is_admin?
    current_user && current_user.admin
  end
  
  def check_admin
    unless is_admin?
      redirect_to '/documents', :error => "You don't have permissions for this action."
      false
    end
  end   
end
