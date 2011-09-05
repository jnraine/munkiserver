require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Auto-require default libraries and those for the current Rails environment.
Bundler.require :default, Rails.env

module Munki
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
      
    # Load server configuration YAML file
    settings = nil
    begin
      settings = YAML.load(File.read("#{Rails.root}/config/settings.yaml"))
    rescue Errno::ENOENT
      # config/settings.yaml doesn't exist
    end
    
    # Add additional load paths for your own custom dirs
    # config.load_paths += %W( #{config.root}/extras )
    config.autoload_paths += %W(
        #{Rails.root}/app/models/widgets  
        #{Rails.root}/app/models/join_models
        #{Rails.root}/app/models/magic_mixin
        #{Rails.root}/app/models/manifest
        #{Rails.root}/app/models/service
        #{Rails.root}/app/models/privilege_granters
        #{Rails.root}/lib
    )

    # Add custom mime types
    Mime::Type.register "text/plist", :plist
    
    # Where we store the packages
    PACKAGE_DIR = Rails.root + "packages"
    # Make sure the dir exists
    FileUtils.mkdir_p(PACKAGE_DIR)
    # Command line utilities
    MAKEPKGINFO = Pathname.new("/usr/local/munki/makepkginfo")
    
    config.cache_store = :memory_store
    
    # A secret is required to generate an integrity hash for cookie session data
    config.secret_token = "407738ccc1518e5a71714d7dc16365c424732e543d791c22bffca1d6d8ac6949e08688836cc69635dc29a8d48b607bd73cb26bcad384c1fbecee44f552f8070c"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters << :password
    config.filter_parameters << :pass # Create session uses params[:pass]
    
    # puts "X-Sendfile header is: " + config.action_dispatch.x_sendfile_header
    # config.action_dispatch.x_sendfile_header = "X-Sendfile"
    
    # Setup action mailer settings
    if settings.present? and settings[:action_mailer].present?
      config.action_mailer.default_url_options = { :host => settings[:action_mailer][:host] }
      config.action_mailer.delivery_method = :sendmail
      # config.action_mailer.delivery_method = settings[:action_mailer][:delivery_method] 
      # config.action_mailer.sendmail_settings = settings[:action_mailer][:sendmail_settings] if settings[:action_mailer][:delivery_method] == :sendmail
      # config.action_mailer.smtp_settings = settings[:action_mailer][:smtp_settings] if settings[:action_mailer][:delivery_method] == :smtp
      # config.action_mailer.raise_delivery_errors = true
    else
      config.action_mailer.delivery_method = :sendmail
    end
  end
end