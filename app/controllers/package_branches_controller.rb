class PackageBranchesController < ApplicationController
  def edit
  end

  def update
    respond_to do |format|
      @package_branch.version_tracker_web_id = params[:package_branch].delete(:version_tracker_web_id)
      
      if @package_branch.update_attributes(params[:package_branch])
        flash[:notice] = "#{@package_branch.display_name} was successfully updated."
        format.html { redirect_to edit_package_branch_path(@package_branch.to_params) }
      else
        flash[:error] = "An error occurred while updating #{@package_branch.display_name}"
        format.html { render :action => "edit" }
      end
    end
  end
      
  # Load a singular resource into @package for all actions
  def load_singular_resource
    action = params[:action].to_sym
    if [:edit, :update].include?(action)
      @package_branch = PackageBranch.unit(current_unit).find_by_name(params[:name])
    else
      raise Exception.new("Unable to load singular resource for #{action} action in #{params[:controller]} controller.")
    end
  end
end
