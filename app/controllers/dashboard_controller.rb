class DashboardController < ApplicationController
  def index
  end
  
  # Loads widget to page using JS
  def widget
    @widget = "#{params[:name].camelize}Widget".constantize.new(current_user)
    respond_to do |format|
      format.js
    end
  end
end
