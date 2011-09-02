class SessionsController < ApplicationController
  skip_before_filter :require_login, :only => ['new','create','destroy']
  
  def new
    redirect_to dashboard_path if logged_in?
  end
  
  # Creates a new user session
  def create
    u = User.authenticate(params[:username],params[:pass])
    if u.nil?
      flash[:error] = "Incorrect username or password"
      redirect_to login_path
    elsif u.unit_ids.empty?
      flash[:warning] = "You are not permitted to any units!"
      render error_page
    else
      session[:username] = u.username
      unit = Unit.find(u.unit_ids.first)
      if params[:redirect].present?
        redirect_to params[:redirect]
      else
        redirect_to dashboard_path
      end
    end
  end
  
  # Logs the user out of the current session
  def destroy
    session[:username] = nil
    session[:unit_id] = nil
    flash[:notice] = "You have been logged out of your session"
    redirect_to login_path
  end
end