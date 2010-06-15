class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery
  
  before_filter :require_login
  
  def super_user?
    puts "From app con"
    current_user.super_user?
  end
  
  def current_unit
    begin
      @current_unit ||= Unit.find(session[:unit_id])
    rescue ActiveRecord::RecordNotFound
    end
  end
  
  def current_user
    @current_user ||= User.find_by_username(session[:username])
  end
  
  def logged_in?
    current_user != nil
  end
  
  # Run a rake task in the background
  # TO-DO could improve performance if using a gem (rake loads environment every single time)
  def call_rake(task, options = {})
    options[:rails_env] ||= Rails.env
    args = options.map { |k,v| "#{k.to_s.upcase}='#{v}'" }
    system "rake #{task} #{args.join(' ')} --trace >> #{Rails.root}/log/rake.log &"
  end
  
  # Redirects user to login path if logged_in returns false
  def require_login
    unless logged_in? or excluded?
      flash[:warning] = "You must be logged in to view that page"
      redirect_to login_path
    end
  end
  
  # Checks to see if the requested page is excluded from login requirements
  # hashes like this: action => [formats, as, array]
  def excluded?
    excluded = false
    # Specify what actions and formats are allowed
    allowed = {:show => [:manifest, :client_prefs, :plist],:download => [:all]}
    # Set format
    format = params[:format].nil? ? "" : params[:format]
    allowed.each do |action,allowed_formats|
      # See if this action/format combo was included
      excluded = true if (action.to_s == params[:action] and allowed_formats.include?(format.to_sym)) or allowed_formats.include?(:all)
    end
    excluded
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
