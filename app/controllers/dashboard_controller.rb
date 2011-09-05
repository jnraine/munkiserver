class DashboardController < ApplicationController
  skip_before_filter :load_singular_resource
  skip_before_filter :require_valid_unit
  
  def index
  end
  
  # Loads widget to page using JS
  def widget
    @widget = "#{params[:name].camelize}Widget".constantize.new(current_user)
    respond_to do |format|
      format.js
    end
  end
  
  private
  def authorize_resource
    authorize! params[:action], :dashboard
  end
end
