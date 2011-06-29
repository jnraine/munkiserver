class SessionsController < ApplicationController
  skip_before_filter :require_login, :only => ['new','create','destroy']
  
  def new
    redirect_to computers_path(current_user.units.first) if logged_in?
  end
  
  # Creates a new user session
  def create
    u = User.authenticate(params[:username],params[:pass])
    if u.nil?
      flash[:error] = "Incorrect username or password"
      redirect_to login_path
    elsif u.unit_ids.empty?
      flash[:warning] = "You are not permitted to any units!"
      render :file => "#{Rails.root}/public/generic_error.html", :layout => false
    else
      session[:username] = u.username
      session[:unit_id] = u.unit_ids.first
      params[:units] = Unit.find(u.unit_ids.first)
      redirect_to computers_path(params[:units])
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