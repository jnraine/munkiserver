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
  
  def download_icon
    respond_to do |format|
      if @package_branch.present?
        format.png do
          send_file @package_branch.icon.path(:medium), :filename => "#{@package_branch.name}.png"
          fresh_when :etag => @package_branch, :last_modified => @package_branch.updated_at.utc, :public => true
        end
      else
        render page_not_found
      end
    end
  end
  
  # Load a singular resource into @package for all actions
  def load_singular_resource
    action = params[:action].to_sym
    if [:edit, :update].include?(action)
      @package_branch = PackageBranch.unit(current_unit).find_by_name(params[:name])
    elsif [:download_icon].include?(action)
      @package_branch = PackageBranch.where(name: params[:id]).first
    else
      raise Exception.new("Unable to load singular resource for #{action} action in #{params[:controller]} controller.")
    end
  end
end
