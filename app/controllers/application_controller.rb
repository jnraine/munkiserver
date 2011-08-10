class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery :except => [:checkin]
  check_authorization
    
  private
  
  include ApplicationHelper
  
  # Run a rake task in the background
  # TO-DO could improve performance if using a gem (rake loads environment every single time)
  def call_rake(task, options = {})
    options[:rails_env] ||= Rails.env
    args = options.map { |k,v| "#{k.to_s.upcase}='#{v}'" }
    system "rake #{task} #{args.join(' ')} --trace >> #{Rails.root}/log/rake.log &"
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
  def current_ability
    if action_and_format_excluded?
      # TODO - HTTP Basic Auth will go here
      @current_ability ||= Ability.new(role: :computer, )
    else
      @current_ability ||= Ability.new(user: current_user, unit: current_unit)
    end
  end
  
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = exception.message
    redirect_to root_url
  end
end
