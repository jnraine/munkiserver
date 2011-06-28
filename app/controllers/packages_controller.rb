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
        format.html { redirect_to edit_package_path(@package.unit, @package) }
        render :json => {:name => @package.package_branch.name }, :content_type => 'text/html'
      else
        # Failure
        flash[:error] = "Failed to add package"
        flash[:error] = flash[:error] + ": " + exceptionMessage if exceptionMessage.present?
        format.html { redirect_to :back }
        render :json => { :result => 'error'}, :content_type => 'text/html'
      end
    end
  end

  def destroy
    @package = Package.find(params[:id])
    
    if @package.destroy
      flash[:notice] = "Package was destroyed successfully"
    end
    
    respond_to do |format|
      format.html { redirect_to packages_path(@package.unit, @package) }
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
        format.html { redirect_to package_path(@package.unit, @package) }
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
    @package = Package.find(params[:id])
    
    respond_to do |format|
      format.html
      format.plist { render :text => @package.to_plist }
    end
  end
  
  # Allows multiple edits
  def multiple_edit
    @packages = Package.find(params[:selected_records])
  end
  
  def multiple_update
    @packages = Package.find(params[:selected_records])
    p = params[:package]
    results = []
    exceptionMessage = nil
    begin
      results = Package.bulk_update_attributes(@packages, p)
    rescue PackageError => e
      exceptionMessage = e.to_s
    end
    
    respond_to do |format|
        if results.empty?
          flash[:error] = exceptionMessage
          format.html { redirect_to(:action => "index") }
        elsif !results.include?(false)
          flash[:notice] = "All #{results.length} packages were successfully updated."
          format.html { redirect_to(:action => "index") } 
        elsif results.include?(false) && results.include?(true)
          flash[:warning] = "#{results.delete_if {|e| e}.length} of #{results.length} packages updated."
          format.html { redirect_to(:action => "index") }
        elsif !results.include?(true)
          flash[:error] = "None of the #{results.length} packages were updated !"
          format.html { redirect_to(:action => "index") }
        end
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
    # for each package that has updates available send an email to the admin
    PackageBranch.available_updates(current_unit).each do |package|
      AdminMailer.package_update_available(package).deliver
    end
    redirect_to(:action => "index")
  end
end