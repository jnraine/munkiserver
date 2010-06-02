class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery
  
  before_filter :require_login
  
  def super_user?
    current_user.super_user?
  end
  
  def current_unit
    Unit.find(session[:unit_id])
  end
  
  def current_user
    User.find_by_username(session[:username])
  end
  
  def logged_in?
    current_user != nil
  end
  
  # Redirects user to login path if logged_in returns false
  def require_login
    unless logged_in?
      flash[:warning] = "You must be logged in to view that page"
      redirect_to login_path
    end
  end
  
  def fake_login
    session[:username] = "jraine"
  end
  
  protected
  
  # Sets the Authorization.current_user to the current_user
  # This is required by the declarative_authorization gem
  def set_current_user_for_auth
    Authorization.current_user = current_user
  end
end
