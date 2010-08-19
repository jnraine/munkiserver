class SessionsController < ApplicationController
  skip_before_filter :require_login, :only => ['new','create','destroy']
  
  def new
    redirect_to root_path if logged_in?
  end
  
  # Creates a new user session
  def create
    u = User.authenticate(params[:username],params[:pass])
    if u.nil?
      flash[:error] = "Incorrect username or password"
      redirect_to login_path
    else
      session[:username] = u.username
      session[:unit_id] = u.unit_ids.first
      redirect_to root_path
    end
  end
  
  # Switches the unit_id session var if the current user is a member of that unit
  def update
    new_unit = Unit.find(params[:unit_id])
    if current_user.member_of(new_unit)
      session[:unit_id] = params[:unit_id]
    end
    # Don't redirect to show or edit actions
    excluded_actions = ["show", "edit"]
    if excluded_actions.include?(params[:a])
      params[:a] = "index"
    end
    redirect_to :action => params[:a], :controller => params[:c]
  end
  
  # Logs the user out of the current session
  def destroy
    session[:username] = nil
    session[:unit_id] = nil
    flash[:notice] = "You have been logged out of your session"
    redirect_to login_path
  end
end