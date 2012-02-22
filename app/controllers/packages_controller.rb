class PackagesController < ApplicationController
  cache_sweeper :package_sweeper, :only => [:create, :edit, :destroy]
  
  def index
    # TO-DO This query can be rethought because of the way the view uses this list of packages
    # it might be better to grab all the package branches from this environment and then iterate
    # through those grabbing all the different versions using the @packages@ method.
    @packages = Package.latest_from_unit_and_environment(current_unit,current_environment).sort{|a,b|a.package_branch.name <=> b.package_branch.name}

    respond_to do |format|
      format.html
    end
  end

  def show
    respond_to do |format|
      if @package.present?
        format.html
        format.plist { render :text => @package.to_plist }
      else
        format.html { render page_not_found }
        format.plist { render page_not_found }
      end
    end
  end

  def edit
    @package.environment_id = params[:environment_id] if params[:environment_id].present?
  end

  def update
    respond_to do |format|
      if @package.update_attributes(params[:package])
        flash[:notice] = "Package was successfully updated."
        format.html { redirect_to package_path(@package.to_params) }
        format.xml { head :ok }
      else
        flash[:error] = "Could not update package!"
        format.html { render :action => "edit" }
        format.xml { render :xml => @package.errors, :status => :unprocessable_entity }
      end
    end
  end

  def new
  end

  def create
    exceptionMessage = nil
    begin
      @package = Package.create(:package_file => params[:package_file],
                                :pkginfo_file => params[:pkginfo_file],
                                :makepkginfo_options => params[:makepkginfo_options],
                                :special_attributes => {:unit_id => current_unit.id})
    rescue PackageError => e
      exceptionMessage = e.to_s
    end

    respond_to do |format|
      if @package.save
        # Success
        flash[:notice] = "Package successfully saved"
        format.html { redirect_to edit_package_path(@package.to_params) }
      else
        # Failure
        flash[:error] = "Failed to add package"
        flash[:error] = flash[:error] + ": " + exceptionMessage if exceptionMessage.present?
        format.html { render :action => "new"}
      end
    end
  end

  def destroy
    if @package.destroy
        flash[:notice] = "Package was destroyed successfully"
    end
    
    respond_to do |format|
      format.html { redirect_to packages_path(current_unit) }
    end
  end
  
  # Allows multiple edits
  def edit_multiple
    @packages = Package.find(params[:selected_records])
  end
  
  def update_multiple
    results = {}
    exceptionMessage = nil
    begin
      @packages = Package.where(:id => params[:selected_records])
      results = Package.bulk_update_attributes(@packages, params[:package])
    rescue PackageError => e
      exceptionMessage = e.to_s
    end
    
    respond_to do |format|
      if exceptionMessage
        flash[:error] = "A problem occurred: " + exceptionMessage
      elsif results[:total] == results[:successes] and results[:failures] == 0
        flash[:notice] = "All #{results[:total]} packages were successfully updated."
      elsif results[:total] == results[:failures] and results[:successes] == 0
        flash[:error] = "None of the #{results[:total]} packages were updated!"
      elsif results[:successes] > 0 and results[:failures] > 0
        flash[:warning] = "#{results[:successes]} of #{results[:total]} packages updated."
      else
        flash[:error] = "Something weird happened. Here are the results: #{results.inspect}"
      end
      format.html { redirect_to packages_path }
    end
  end
  
  
  # Used to download the actual package (typically a .dmg)
  def download
    respond_to do |format|
      if @package.present?
        format.html do
          send_file Munki::Application::PACKAGE_DIR + @package.installer_item_location, :filename => @package.to_s(:download_filename)
          fresh_when :etag => @package, :last_modified => @package.created_at.utc, :public => true
        end
        
        format.json { render :text => @package.to_json(:methods => [:name, :display_name]) }
      else
        render page_not_found
      end
    end
  end
  
  # Used to check for available updates across all units
  def check_for_updates
    call_rake("packages:check_for_updates")
    flash[:notice] = "Checking for updates now"
    redirect_to :back
  end
  
  def environment_change
    @environment_id = params[:environment_id] if params[:environment_id].present?
    
    respond_to do |format|
      format.js
    end
  end

  def index_shared
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
  def import_shared
    shared_package = Package.shared.where("unit_id != #{current_unit.id}").find(params[:id])
    imported_package = Package.import_package(current_unit, shared_package)
    
    respond_to do |format|
      if imported_package.save
        flash[:notice] = "Successfully imported #{shared_package.display_name} (#{shared_package.version})"
        format.html { redirect_to edit_package_path(imported_package.to_params) }
      else
        flash[:error] = "Unable to import #{shared_package.display_name} (#{shared_package.version})"
        format.html { redirect_to shared_packages_path(current_unit) }
      end
    end
  end
  
  # Import two or more packages from other units,
  # after import default to staging enviroment, and package shared status to false
  def import_multiple_shared
    shared_packages = Package.shared.where("unit_id != #{current_unit.id}").find(params[:selected_records])
    results = []
    shared_packages.each do |shared_package|
      package = Package.import_package(current_unit, shared_package)
      results << package.save
    end
    respond_to do |format|
      if results.include?(false)
        flash[:error] = "Failed to import packages"
        format.html { redirect_to shared_packages_path(current_unit) }
      else
        flash[:notice] = "Successfully imported packages"
        format.html { redirect_to shared_packages_path(current_unit) }
      end
    end
  end
  
  private
  # Load a singular resource into @package for all actions
  def load_singular_resource
    action = params[:action].to_sym
    if [:show, :edit, :update, :destroy].include?(action)
      @package = Package.find_where_params(params)
    elsif [:index, :new, :create, :edit_multiple, :update_multiple, :check_for_updates, :index_shared, :import_shared, :import_multiple_shared].include?(action)
      @package = Package.new(:unit_id => current_unit.id)
    elsif [:download].include?(action)      
      @package = Package.find(params[:id].to_i)
    elsif [:environment_change].include?(action)      
      @package = Package.find(params[:package_id])
    else
      raise Exception.new("Unable to load singular resource for #{action} action in #{params[:controller]} controller.")
    end
  end
end