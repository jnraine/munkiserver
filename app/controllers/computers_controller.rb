require 'cgi'

class ComputersController < ApplicationController
  helper_method :sort_column, :sort_direction
  
  def index
    # Scope computers to unit/environment and then order by relevent column and direction
    @computers = Computer.unit_and_environment(current_unit, current_environment)
    @computers = @computers.order(sort_column + ' ' + sort_direction)
    
    # Search for value on name attribute
    @computers = @computers.search(:name, params[:name])
    
    # Add pagination using will_paginate gem
    per_page = params[:per_page]
    per_page ||= Computer.per_page
    @computers = @computers.paginate(:page => params[:page], :per_page => per_page)
    
    respond_to do |format|
      format.html # index.html
      format.js # index.js
    end
  end

  def new
    respond_to do |format|
      format.html
      format.js { render :action => "edit" }
    end
  end

  def create
    # Recreating a new computer object instead of using the one we already created in load_singular_resource
    @computer = Computer.new(params[:computer].merge({:unit_id => current_unit.id}))
    
    respond_to do |format|
      if @computer.save
        flash[:notice] = "#{@computer} was successfully created."
        format.html { redirect_to computer_path(@computer.unit, @computer) }
      else
        flash[:error] = "Failed to create #{@computer} computer object!"
        format.html { render :action => "new"}
      end
    end
  end
  
  def show
    respond_to do |format|
      if @computer.present?
        format.html
        format.manifest { render :text => @computer.to_plist}
        format.plist { render :text => @computer.to_plist}
        format.client_prefs { render :text => @computer.client_prefs.to_plist }
      else
        MissingManifest.find_or_create_by_manifest_type_and_identifier_and_request_ip({:manifest_type => Computer.to_s, :identifier => params[:id], :request_ip => request.remote_ip})
        format.manifest { render :file => "public/404.html", :status => 404, :layout => false}
        format.html { render :file => "public/404.html", :status => 404, :layout => false }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @computer.update_attributes(params[:computer])
        flash[:notice] = "#{@computer.name} was successfully updated."
        format.html { redirect_to computer_path(@computer.unit, @computer) }
      else
        flash[:error] = 'Could not update computer!'
        format.html { render :action => "edit" }
      end
    end 
  end

  def destroy
    if @computer.destroy
      flash[:notice] = "Computer was destroyed successfully"
    end
    
    respond_to do |format|
      format.html { redirect_to computers_path(current_unit) }
    end
  end


  # Import an ARD plist form
  def import
  end
  
  # Take ARD plist and create new computer objects
  # TO-DO when a computer object import fails, tell
  # the user what went wrong (by print the computer.errors hash)
  def create_import
    begin
      @computers = ComputerService.import(params[:computer],current_unit)
    rescue NoMethodError
      e = "Please select a plist file"
    rescue => e
    end
      
    unless @computers.nil?
      @total = @computers.count
      # Save each computer.  If it doesn't save, leave it out of the array
      @computers = @computers.collect {|e| e if e.save}.compact
    end
    
    respond_to do |format|
      if @computers.nil?
        flash[:error] = "There was a problem while parsing the plist: #{e}"
        format.html { redirect_to import_new_computer_path(current_unit) }
      elsif @computers.count > 0
        flash[:notice] = "#{@computers.count} of #{@total} computers imported into #{@computers.first.computer_group}"
        format.html { redirect_to computers_path(current_unit) }
      else
        flash[:warning] = "Zero computers were imported.  Did the ARD list have any members?"
        format.html { redirect_to computers_path(current_unit) }
      end
    end
  end
  
  # Allows a computer to checkin with the server, notifying it
  # of the last successful munki run.  May be extended in the future.
  def checkin
    if params[:managed_install_report_plist].present?
      report_hash = ManagedInstallReport.format_report_plist(params[:managed_install_report_plist]).merge({:ip => request.remote_ip})
      @computer.managed_install_reports.build(report_hash)
    end
    
    if params[:system_profiler_plist].present?
      system_profile_hash = SystemProfile.format_system_profiler_plist(params[:system_profiler_plist])
      sp = SystemProfile.find_or_create_by_computer_id(@computer.id)
      @computer.system_profile.attributes = system_profile_hash
    end
    
    @computer.save
    
    if @computer.warranty.present? and @computer.serial_number != @computer.warranty.serial_number
      @computer.warranty.destroy
    end
    
    AdminMailer.computer_report(@computer).deliver if @computer.report_due?
    render :text => ''
  end
  
  
  # Allows multiple edits
  def edit_multiple
    @computers = Computer.find(params[:selected_records])
    @environment_id = params[:environment_id] if params[:environment_id].present?
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def update_multiple
    @computers = Computer.find(params[:selected_records])
    p = params[:computer]
    results = []
    exceptionMessage = nil
    begin
      results = Computer.bulk_update_attributes(@computers, p)
    rescue ComputerError => e
      exceptionMessage = e.to_s
    end

    respond_to do |format|
        if results.empty?
          flash[:error] = exceptionMessage
          format.html { redirect_to(:action => "index") }
        elsif !results.include?(false)
          flash[:notice] = "All #{results.length} computer objects were successfully updated."
          format.html { redirect_to(:action => "index") }
        elsif results.include?(false) && results.include?(true)
          flash[:warning] = "#{results.delete_if {|e| e}.length} of #{results.length} computer objects updated."
          format.html { redirect_to(:action => "index") }
        elsif !results.include?(true)
          flash[:error] = "None of the #{results.length} computer objects were updated !"
          format.html { redirect_to(:action => "index") }
        end
    end
  end
  
  def environment_change
    @environment_id = params[:environment_id] if params[:environment_id].present?
    
    respond_to do |format|
      format.js
    end
  end
  
  def unit_change
    @computer.unit_id = params[:unit_id]
    @unit = Unit.find(params[:unit_id])
    @environment_id = current_environment.id
    
    respond_to do |format|
      format.js
    end
  end
  
  def update_warranty
    @computer = Computer.find_for_show(params[:unit_shortname], params[:computer_id])
    if @computer.update_warranty
      flash[:notice] = "#{@computer.name}'s warranty was successfully updated."
    else
      flash[:error] = "#{@computer.name}'s warranty could not be updated."
    end
    redirect_to computer_path(@computer.unit, @computer, :anchor => 'warranty_tab')
  end
  
  private
  # Load a singular resource into @computer for all actions
  # This is really dense...refactor?
  def load_singular_resource
    action = params[:action].to_sym
    if [:show, :edit, :update, :destroy].include?(action)      
      @computer = Computer.find_for_show(params[:unit_shortname], CGI::unescape(params[:id]))
    elsif [:update_warranty].include?(action)      
      @computer = Computer.find_for_show(params[:unit_shortname], CGI::unescape(params[:computer_id]))
    elsif [:index, :new, :create, :edit_multiple, :update_multiple, :import, :create_import].include?(action)      
      @computer = Computer.new({:unit_id => current_unit.id})
    elsif [:unit_change].include?(action)      
      @computer = Computer.find(params[:computer_id])
    elsif [:environment_change].include?(action)
      if params[:computer_id] == "new"
        @computer = Computer.new({:unit_id => current_unit.id})
      else
        @computer = Computer.find_for_show(params[:unit_shortname], params[:computer_id])
      end
    elsif [:checkin].include?(action)
      @computer = Computer.find_for_show(nil, params[:id])
    else
      raise Exception("Unable to load singular resource for #{action} action in #{params[:controller]} controller.")
    end
  end
  
  # Helper method to minimize errors and SQL injection attacks
  def sort_column
    %w[name hostname mac_address last_report_at].include?(params[:sort]) ? params[:sort] : "name"
  end
  
  # Helper method to minimize errors and SQL injection attacks  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end  
end
