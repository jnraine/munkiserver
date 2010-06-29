class PackagesController < ApplicationController
  def index
    # Set environment
    @env = Environment.find_by_id(params[:eid])
    @env ||= Environment.default_view
    # TO-DO This query can be rethought because of the way the view uses this list of packages
    # it might be better to grab all the package branches from this environment and then iterate
    # through those grabbing all the different versions using the @packages@ method.
    @packages = Package.latest_from_unit_and_environment(current_unit,@env)

    respond_to do |format|
      format.html
    end
  end

  def create 
    # Assign @h
    begin
      # If you upload a package
      @h = Package.upload(params[:data],params[:options]) unless params[:data].nil?
      # If you pass a version tracker ID
      @h = VersionTracker.find_or_create_by_web_id(params[:version_tracker_web_id]).to_package unless params[:version_tracker_web_id].nil?
    rescue PackageError => e
      invalid_package = true
      flash[:error] = "Invalid package uploaded: #{e.message}"
    rescue AutoPackageError => e
      invalid_package = true
      flash[:error] = "There was a problem while auto packaging: #{e.message}"
    end

    # Assign @package
    unless @h.nil? or @h[:package].nil?
      @package = @h[:package]
      @package.unit = current_unit
    else
      @package = Package.new
    end
    
    respond_to do |format|
      if !invalid_package and @package.save
        # Success
        flash[:notice] = "Package successfully saved"
        format.html { redirect_to edit_package_path(@package) }
      else
        # Failure
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
    debugger
    # @package_service = PackageService.new(@package,params[:package])
  
    respond_to do |format|
      if @package.save
        flash[:notice] = "Package was successfully updated."
        format.html { redirect_to package_path(@package) }
        format.xml { head :ok }
      else
        flash[:error] = "Could not update package!"
        format.html { redirect_to edit_package(@package) }
        format.xml { render :xml => @package.errors, :status => :unprocessable_entity }
      end
    end
  end

  def new
    @package = Package.new
  end

  def show
    @package = Package.find(params[:id])
    
    respond_to do |format|
      format.html
      format.plist { render :text => @package.to_plist }
    end
  end
  
  # Used to download the actual package (typically a .dmg)
  def download
    send_file Munki::Application::PACKAGE_DIR + params[:installer_item_location]
  end
  
  # Used to check for available updates across all units
  def check_for_updated
    call_rake("packages:check_for_updates")
    flash[:notice] = "Checking for updates now"
    redirect_to :back
  end
end