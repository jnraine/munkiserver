class DashboardController < ApplicationController
  skip_before_filter :load_singular_resource
  
  def index
  end
  
  # Loads widget to page using JS
  def widget
    @widget = "#{params[:name].camelize}Widget".constantize.new(current_user)
    respond_to do |format|
      format.js
    end
  end
  
  def dismiss_manifest
    respond_to do |format|
      @missing_manifest = MissingManifest.find(params[:id])
      @missing_manifest.update_attributes :dismissed => true
      format.js
    end
  end
  
  private
  def authorize_resource
    authorize! params[:action], :dashboard
  end
end
