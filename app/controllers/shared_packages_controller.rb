class SharedPackagesController < ApplicationController
  before_filter :require_valid_unit
  filter_access_to :all
  
  def index
    @shared_packages = Package.shared_to_unit(current_unit)
    @imported_packages = Package.shared_to_unit_and_imported(current_unit)
  end
  
  # Updates the shared package resource by adding a new instance of that package
  # to the current unit.  This is very basic and gets complicated when that package
  # has dependencies.  This still needs to be sorted out.
  def import
    @shared_package = Package.shared.where("unit_id != #{current_unit.id}").find(params[:id])
    @package = Package.new(@shared_package.attributes)
    
    # Do custom stuff to imported package
    @package.unit = current_unit
    @package.environment = Environment.start
    @package.update_for = []
    @package.requires = []
    @package.icon = @shared_package.icon
    @package.shared = false
    
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
end
