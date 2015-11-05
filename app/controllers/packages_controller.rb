class PackagesController < ApplicationController
  cache_sweeper :package_sweeper, :only => [:create, :edit, :destroy]
  
  def index
    @package_branches = PackageBranch.find_for_index(current_unit, current_environment).uniq_by {|branch| branch.id }
    @environments = Environment.all

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
    process_package_upload = ProcessPackageUpload.new(:package_file => params[:package_file],
                                                      :file_url => params[:file_url],
                                                      :pkginfo_file => params[:pkginfo_file],
                                                      :makepkginfo_options => params[:makepkginfo_options], 
                                                      :special_attributes => {:unit_id => current_unit.id})
    process_package_upload.process

    respond_to do |format|
      if process_package_upload.processed?
        flash[:notice] = "Package successfully uploaded"
        format.html { redirect_to edit_package_path process_package_upload.package.to_params }
      else
        flash[:error] = "A problem occurred while processing package upload: #{process_package_upload.error_message}"
        format.html { render :action => :new }
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

    if params[:commit] == 'Delete'
      computercount = params[:selected_records].length
      params[:selected_records].each do |computer|
        @computers = Computer.where(:id => params[:selected_records])
        @computers.each do |this|
          # results = this.destroy
          this.destroy
        end
      end
      redirect_to computers_path, :flash => { :notice => "All #{computercount} selected computer records were successfully deleted." }
      return
    end

    if params[:commit] == 'Delete'
      packagecount = params[:selected_records].length
      params[:selected_records].each do |package|
        @packages = Package.where(:id => params[:selected_records])
        @packages.each do |this|
          # results = this.destroy
          this.destroy
        end
      end
      redirect_to packages_path, :flash => { :notice => "All #{packagecount} selected packages were successfully deleted." }
      return
    end
  
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
  
  # Used to download the package icon for Munki 2 as a .png
  def icon
    respond_to do |format|
      if @package.present?
        format.png do
          send_file @package.icon.photo.path, :url_based_filename => true, :type => "image/png", :disposition => "inline"
          fresh_when :etag => @package, :last_modified => @package.created_at.utc, :public => true
        end
      else
        render page_not_found
      end
    end
  end
  
    
  
  # Used to check for available updates across all units
  def check_for_updates
    Backgrounder.call_rake("packages:check_for_updates")
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
    @branches = PackageBranch.not_unit(current_unit).shared.includes(:shared_packages)
    @grouped_branches = @branches.group_by {|branch| branch.unit }
  end
  
  # Import shared packages from another unit
  def import_multiple_shared
    cloned_packages = Package.clone_packages(Package.shared.where(:id => params[:selected_records]), current_unit)
    save_results = cloned_packages.map(&:save)

    respond_to do |format|
      unless save_results.include?(false)
        flash[:notice] = "Successfully imported packages"
      else  
        flash[:error] = "Failed to import all or some packages"
      end
      
      format.html { redirect_to shared_packages_path(current_unit) }
    end
  end
    
  # Load a singular resource into @package for all actions
  def load_singular_resource
    action = params[:action].to_sym
    if [:show, :edit, :update, :destroy].include?(action)
      @package = Package.find_where_params(params)
    elsif [:index, :new, :create, :edit_multiple, :update_multiple, :check_for_updates, :index_shared, :import_shared, :import_multiple_shared].include?(action)
      @package = Package.new(:unit_id => current_unit.id)
    elsif [:download].include?(action)      
      @package = Package.find(params[:id].to_i)
    elsif [:icon].include?(action)
      package_branch = PackageBranch.where(:name => params[:package_branch]).first
      @package = Package.where(:package_branch_id => package_branch.id).last
    elsif [:environment_change].include?(action)      
      @package = Package.find(params[:package_id])
    else
      raise Exception.new("Unable to load singular resource for #{action} action in #{params[:controller]} controller.")
    end
  end
end
