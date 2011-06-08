class PackagesController < ApplicationController
  def index
    # TO-DO This query can be rethought because of the way the view uses this list of packages
    # it might be better to grab all the package branches from this environment and then iterate
    # through those grabbing all the different versions using the @packages@ method.
    @packages = Package.latest_from_unit_and_environment(current_unit,current_environment)

    respond_to do |format|
      format.html
    end
  end

  def create
    exceptionMessage = nil
    begin
      @package = Package.create_from_uploaded_file(params[:package_file],params[:pkginfo_file], {:makepkginfo_options => params[:makepkginfo_options],
                                                                                            :attributes => {:unit_id => current_unit.id}})
    rescue PackageError => e
      @package = Package.new
      exceptionMessage = e.to_s
    end
    
    respond_to do |format|
      if @package.save
        # Success
        flash[:notice] = "Package successfully saved"
        format.html { redirect_to edit_package_path(@package) }
      else
        # Failure
        flash[:error] = "Failed to add package"
        flash[:error] = flash[:error] + ": " + exceptionMessage if exceptionMessage.present?
        
        format.html { redirect_to :back }
      end
    end
  end

  def destroy
    @package = Package.find(params[:id])
    
    if @package.destroy
      flash[:notice] = "Package was destroyed successfully"
    end
    
    respond_to do |format|
      format.html { redirect_to packages_path }
    end
  end

  def edit
    @package = Package.find(params[:id])
  end

  def update
    @package = Package.unit(current_unit).find(params[:id])

    respond_to do |format|
      if @package.update_attributes(params[:package])
        flash[:notice] = "Package was successfully updated."
        format.html { redirect_to package_path(@package) }
        format.xml { head :ok }
      else
        flash[:error] = "Could not update package!"
        format.html { render :action => "edit" }
        format.xml { render :xml => @package.errors, :status => :unprocessable_entity }
      end
    end
  end

  def new
    @package = Package.new
  end

  def show
    # @package = PackageBranch.find_by_name(params[:id])
    @package = Package.find(params[:id])
    
    respond_to do |format|
      format.html
      format.plist { render :text => @package.to_plist }
    end
  end
  
  # Used to download the actual package (typically a .dmg)
  def download
    @package = Package.find(params[:id])
    if @package.present?
      send_file Munki::Application::PACKAGE_DIR + @package.installer_item_location, :filename => @package.to_s(:download_filename)
    else
      render :template => "404.html", :status => :not_found
    end
  end
  
  # Used to check for available updates across all units
  def check_for_updated
    call_rake("packages:check_for_updates")
    flash[:notice] = "Checking for updates now"
    redirect_to :back
  end
end