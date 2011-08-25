class DashboardController < ApplicationController
  def index
    @widgets = DashboardWidget.all
  end
end
