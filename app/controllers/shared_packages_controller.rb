class SharedPackagesController < ApplicationController
  before_filter :require_valid_unit
  def index
    # @packages = Package.shared_to_unit_and_imported(current_unit)
    
    @packages = Package.shared.where("unit_id != #{current_unit.id}")
    pb_ids = []
    @packages.each do |p|
      pb_ids << p.package_branch_id
    end
    @package_branches = PackageBranch.find(pb_ids.uniq)
    @other_units = Unit.from_other_unit(current_unit)
  end
  
  # Updates the shared package resource by adding a new instance of that package
  # to the current unit.  This is very basic and gets complicated when that package
  # has dependencies.  This still needs to be sorted out.
  def import
    @shared_package = Package.shared.where("unit_id != #{current_unit.id}").find(params[:id])
    @package = Package.import_package(current_unit, @shared_package)
    
    respond_to do |format|
      if @package.save
        flash[:notice] = "Successfully imported #{@shared_package.display_name} (#{@shared_package.version})"
        format.html { redirect_to edit_package_path(@package.to_params) }
      else
        flash[:error] = "Unable to import #{@shared_package.display_name} (#{@shared_package.version})"
        format.html { redirect_to shared_packages_path(current_unit) }
      end
    end
  end
  
  # Import two or more packages from other units,
  # after import default to staging enviroment, and package shared status to false
  def import_multiple
    shared_packages = Package.shared.where("unit_id != #{current_unit.id}").find(params[:selected_records])
    results = []
    shared_packages.each do |shared_package|
      package = Package.import_package(current_unit, shared_package)
      results << package.save
    end
    respond_to do |format|
      if results.include?(false)
        flash[:error] = "Failed to Import packages"
        format.html { redirect_to shared_packages_path(current_unit) }
      else
        flash[:notice] = "Successfully imported packages"
        format.html { redirect_to packages_path(current_unit) }
      end
    end
  end
end
