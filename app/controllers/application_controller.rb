class ApplicationController < ActionController::Base
  protect_from_forgery
  helper :all # include all helpers, all the time
  before_filter :get_project
  before_filter :authenticate_user!
  helper_method :is_admin?

  protected
  def get_project
    subdomain = request.subdomains.first
    unless @project = Project.where(:permalink=>subdomain).first || Project.where(:permalink=>'demo').first
      raise ActionController::RoutingError.new("Error! Project #{subdomain} does not exist.")
      false
    end
  end

  def is_admin?
   current_user && current_user.admin?
  end
end
