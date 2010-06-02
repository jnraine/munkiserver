class PackagesController < ApplicationController
  def index
    # Set environment
    @env = Environment.find_by_id(params[:eid])
    @env ||= Environment.first
    # Get package branches and binds them to the current scope
    @package_branches = PackageBranch.unit_and_environment(current_unit,@env)
    @packages = @package_branches.map(&:latest)
    
    respond_to do |format|
      format.html
    end
  end

  def create
    begin
      @h = Package.upload(params[:data])
      @package = @h[:package]
      @package.unit = current_unit
      invalid_package_upload = false
    rescue InvalidPackageUpload
      @package = Package.new
      invalid_package_upload = true
    end
    
    respond_to do |format|
      if invalid_package_upload == false and @package.save
        flash[:notice] = "Package successfully saved"
        format.html { redirect_to edit_package_path(@package) }
      elsif invalid_package_upload
        flash[:error] = "Invalid package file uploaded!"
        format.html { render new_package_path }
      else
        flash[:error] = "Package failed to save!"
        format.html { render new_package_path }
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
    @package_service = PackageService.new(@package,params[:package])
  
    respond_to do |format|
      if @package_service.save
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
end
