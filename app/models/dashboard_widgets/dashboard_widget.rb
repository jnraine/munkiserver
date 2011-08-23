class DashboardWidget
  attr_accessor :user
  
  def initialize(user)
    @user = user
  end
  
  def render
    ActionView::Base.new(Rails.configuration.paths.app.views.first).render(:partial => partial_name, :locals => {:widget => self, :user => self.user})
  end
  
  def partial_name
    "widgets/#{partialized_class_name}"
  end
  
  def partialized_class_name
    name = self.class.to_s
    name = name.sub(/Widget$/,"")
    name.underscore
  end
end