class DashboardController < ApplicationController
  def index
    @widgets = DashboardWidget.all
    @widget = DashboardWidget
  end
end
