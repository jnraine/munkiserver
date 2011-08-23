class DashboardWidget
  attr_accessor :user
  
  def self.all
    [MissingManifestsWidget]
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
  
  def render
    ActionView::Base.new(Rails.configuration.paths.app.views.first).render(:partial => partial_name, :locals => {:widget => self, :user => self.user})
  end
  
  def partial_name
    "widgets/#{self.class.css_class}"
  end
end