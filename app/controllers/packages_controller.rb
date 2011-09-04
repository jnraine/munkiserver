class PackagesController < ApplicationController
  before_filter :require_valid_unit
  before_filter :find_package_where_params, :only => [:show, :edit, :update, :destroy]
  
  load_and_authorize_resource
  
  def index
    # TO-DO This query can be rethought because of the way the view uses this list of packages
    # it might be better to grab all the package branches from this environment and then iterate
    # through those grabbing all the different versions using the @packages@ method.
    @packages = Package.latest_from_unit_and_environment(current_unit,current_environment)

    respond_to do |format|
      format.html
    end
  end

    def show
      # @package = Package.find_where_params(params)
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
    # @package = Package.find_where_params(params)
    @package.environment_id = params[:environment_id] if params[:environment_id].present?
  end

  def update
    # @package = Package.find_where_params(params)
    
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
    @package = Package.new
  end

  def create
    exceptionMessage = nil
    begin
      @package = Package.create(:package_file => params[:package_file],
                                :pkginfo_file => params[:pkginfo_file],
                                :makepkginfo_options => params[:makepkginfo_options],
                                :special_attributes => {:unit_id => current_unit.id})
    rescue PackageError => e
      @package = Package.new
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
    # @package = Package.find_where_params(params)
    
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
    @package = Package.find(params[:id])
    if @package.present?
      send_file Munki::Application::PACKAGE_DIR + @package.installer_item_location, :filename => @package.to_s(:download_filename)
      fresh_when :etag => @package, :last_modified => @package.created_at.utc, :public => true
    else
      render page_not_found
    end
  end
  
  # Used to check for available updates across all units
  def check_for_updates
    call_rake("packages:check_for_updates")
    flash[:notice] = "Checking for updates now"
    redirect_to :back
  end
  
  def environment_change
    @package = Package.find(params[:package_id])
    @environment_id = params[:environment_id] if params[:environment_id].present?
    
    respond_to do |format|
      format.js
    end
  end
  
  private
  def find_package_where_params
    @package = Package.find_where_params(params)
  end
end