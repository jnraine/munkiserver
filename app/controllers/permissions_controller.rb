class PermissionsController < ApplicationController
  def index
    @principals = User.all + UserGroup.all
    @units = Unit.where(:id => current_user.permission_unit_ids)
    respond_to do |format|
      format.html
    end
  end
  
  def edit
    begin
      @grouped_permissions = Permission.retrieve_in_privilege_groups(:principal_pointer => params[:principal_pointer], :unit_id => params[:unit_id])
      @can_update = (can? :update, @grouped_permissions.values.first)
    rescue ArgumentError => e
      flash[:error] = e.message
    end
    
    respond_to do |format|
      if flash[:error].present?
        format.html { redirect_to permissions_path }
        format.js { render :partial => "shared/flash", :locals => {:flash => flash} }
      else
        format.html
        format.js
      end
    end
  end
  
  def update
    results = Permission.save_permission_set(params[:permissions])
    
    if results[:failed] > 0
      flash[:error] = "An error occurred: failed to save #{results[:failed].length} out of #{results[:total_records]} permissions!"
    elsif
      flash[:notice] = "Successfully saved permissions"
    end
    
    respond_to do |format|
      format.js { render :partial => "shared/flash", :locals => {:flash => flash} }
    end
  end
  
  private
  def load_singular_resource
    # action = params[:action].to_sym
    # 
    # if [:edit, :update].include?(action)      
    #   @permissions = Permission.retrieve(:principal_id => params[:principal_id], :unit_id => params[:unit_id])
    # elsif [:index].include?(action)
    #   @units = Unit.where(:id => current_user.permission_unit_ids)
    # else
    #   raise Exception("Unable to load singular resource for #{action} action in #{params[:controller]} controller.")
    # end
  end
end
