class SharedPackagesController < ApplicationController
  def index
    @shared_packages = Package.shared.where("unit_id != #{current_unit.id}")
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
    
    respond_to do |format|
      if @package.save
        flash[:notice] = "Successfully imported #{@shared_package.display_name} (#{@shared_package.version})"
        format.html { redirect_to edit_package_path(@package) }
      else
        flash[:error] = "Unable to import #{@shared_package.display_name} (#{@shared_package.version})"
        format.html { redirect_to shared_packages_path }
      end
    end
  end
end
