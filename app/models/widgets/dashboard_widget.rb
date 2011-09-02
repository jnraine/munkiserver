class DashboardWidget
  module UrlHelpers
    include Rails.application.routes.url_helpers
  end
  
  module AssetTagHelper
    include ActionView::Helpers::AssetTagHelper
  end
  
  @@action_view = ActionView::Base.new(Rails.configuration.paths.app.views.first)
  @@action_view.extend UrlHelpers
  @@user = nil
  
  attr_accessor :user
  
  def initialize(user)
    @user = user
  end
  
  def self.user
    @@user
  end
  
  def self.user=(user)
    @@user = user
  end
  
  def self.css_class
    name = self.to_s
    name = name.sub(/Widget$/,"")
    name.underscore
  end
  
  def css_class
    self.class.css_class
  end
  
  def self.title
    css_class.titleize
  end
  
  def title
    self.class.title
  end
  
  def render(options = {})
    default_locals = {:widget => self, :user => self.user}
    options[:locals].present? ? options[:locals] = default_locals.merge(options[:locals]) : options[:locals] = default_locals
    action_view.render(:partial => partial_name, :locals => options[:locals])
  end
  
  def action_view
    @@action_view
  end
  
  def partial_name
    "widgets/#{self.class.css_class}"
  end
  
  def partial_path
    partial_name
  end
  
  # Get all the units the user belongs to
  def scoped_units(user)
    ids = user.units.map(&:id)
    Unit.where(:id => ids)
  end
  
  # Get all the computers based on the unit the user belongs to
  def scoped_computers(user, unit_id = nil)
    unit_id ||= user.units
    Computer.where(:unit_id => unit_id).map(&:id)
  end
end