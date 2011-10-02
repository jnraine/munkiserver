class PermissionsController < ApplicationController
  def index
    @principals = User.all + UserGroup.all
    
    respond_to do |format|
      format.html
    end
  end
  
  def edit
    respond_to do |format|
      format.js
    end
  end
  
  def update
    respond_to do |format|
      format.js
    end
  end
  
  private
  def load_singular_resource
    action = params[:action].to_sym

    if [:edit, :update].include?(action)      
      @permissions = Permission.find_for_manage(params)
    elsif [:index].include?(action)
      @units = Unit.where(:id => current_user.permission_unit_ids)
    else
      raise Exception("Unable to load singular resource for #{action} action in #{params[:controller]} controller.")
    end
  end
end
