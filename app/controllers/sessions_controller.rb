class SessionsController < ApplicationController
  skip_before_filter :require_login, :only => ['new','create','destroy']
  skip_before_filter :load_singular_resource
  skip_before_filter :require_valid_unit

  def new
    redirect_to dashboard_path if logged_in?
  end
  
  # Creates a new user session
  def create
    u = User.authenticate(params[:username],params[:pass])
    if u.nil?
      flash[:error] = "Incorrect username or password"
      redirect_to login_path      
    elsif current_user.present? and current_user.units.empty?
      flash[:error] = "You are not permitted to any units!  See the system administrator to gain permissions."
      redirect_to error_page
    else
      session[:username] = u.username
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
  
  private
  def authorize_resource
    authorize! params[:action].to_sym, :session
  end
end