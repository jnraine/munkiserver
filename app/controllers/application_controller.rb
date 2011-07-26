class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery :except => [:checkin]
  
  before_filter :require_login
  
  private
  
  include ApplicationHelper
  
  # Run a rake task in the background
  # TO-DO could improve performance if using a gem (rake loads environment every single time)
  def call_rake(task, options = {})
    options[:rails_env] ||= Rails.env
    args = options.map { |k,v| "#{k.to_s.upcase}='#{v}'" }
    system "rake #{task} #{args.join(' ')} --trace >> #{Rails.root}/log/rake.log &"
  end
  
  # Redirects user to login path if logged_in returns false.
  def require_login
    # If we are logged in or the action we are requesting is excluded from login requirement
    if logged_in? or action_and_format_excluded?
      if logged_in? and current_user.units.empty?
        flash[:warning] = "You are not permitted to any units!"
        render :file => "#{Rails.root}/public/generic_error.html", :layout => false
      end
    else
      flash[:warning] = "You must be logged in to view that page"
      redirect_to login_path(:redirect => request.request_uri)
    end
  end
  
  def require_valid_unit
    begin
      # raise Exception.new("You are not permitted this unit (#{current_unit})") unless current_user.member_of(current_unit)
      current_unit
    rescue Exception => e
      flash[:error] = "The unit you requested (#{params[:unit]}) does not exist or you do not have permission to it!"
      render :file => "#{Rails.root}/public/generic_error.html", :layout => false
    end
  end
  
  # Checks to see if the requested page is excluded from login requirements
  # hashes like this: action => [formats, as, array]
  def action_and_format_excluded?
    excluded = false
    # Specify what actions and formats are allowed
    allowed = {:show => [:manifest, :client_prefs, :plist],:download => [:all], :checkin => [:all]}
    # Set format
    format = params[:format].nil? ? "" : params[:format]
    allowed.each do |action,allowed_formats|
      # See if this action/format combo was included
      if action.to_s == params[:action] and allowed_formats.include?(format.to_sym)
        excluded = true 
      elsif action.to_s == params[:action] and allowed_formats.include?(:all)
        excluded = true
      end
    end
    excluded
  end
  
  def fake_login
    session[:username] = "default"
  end

  def page_not_found
    {:file => "#{Rails.root}/public/404.html", :layout => false, :status => 404}
  end
  
  def error_page
    {:file => "#{Rails.root}/public/generic_error.html", :layout => false}
  end
  
  # Check if the given package has dependency issues if it's required by other packages
  def is_required?(package)
    RequireItem.where(:package_id => package.id).present?
  end
  
  protected
  
  # Sets the Authorization.current_user to the current_user
  # This is required by the declarative_authorization gem
  def set_current_user_for_auth
    Authorization.current_user = current_user
  end
end
