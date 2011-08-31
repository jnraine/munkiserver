class DashboardWidget
  module UrlHelpers
    include Rails.application.routes.url_helpers
  end
  
  @@action_view = ActionView::Base.new(Rails.configuration.paths.app.views.first)
  @@action_view.extend UrlHelpers
  
  attr_accessor :user
  
  def self.all
    [MissingManifestsWidget, RecentInstallErrorsAndWarningsWidget, RecentCheckinsWidget, RecentWarrantyExpireWidget]
  end
  
  def self.missing_manifests
    MissingManifestsWidget
  end
  
  def self.recent_activities
    RecentInstallErrorsAndWarningsWidget
  end
  
  def self.recent_checkins
    RecentCheckinsWidget
  end
  
  def self.recent_warranty_expire
    RecentWarrantyExpireWidget
  end
  
  def self.css_class
    name = self.to_s
    name = name.sub(/Widget$/,"")
    name.underscore
  end
  
  def self.title
    css_class.titleize
  end
  
  def initialize(user)
    @user = user
  end
  
  def render(options = {})
    default_locals = {:widget => self, :user => self.user}
    options[:locals] = default_locals.merge(options[:locals])
    action_view.render(:partial => partial_name, :locals => options[:locals])
  end
  
  def action_view
    @@action_view
  end
  
  def partial_name
    "widgets/#{self.class.css_class}"
  end
end