class ComputersController < ApplicationController
  def index
    # Set environment at view layer
    @computers = ComputerService.collect(params,current_unit,current_environment)
    
    respond_to do |format|
      format.html # index.html
      format.js # index.js
    end
  end

  def new
    @computer = Computer.new
  end

  def create
    @computer = Computer.new(params[:computer])
    @computer.unit = current_unit
    
    respond_to do |format|
      if @computer.save
        flash[:notice] = "#{@computer} was successfully created."
        format.html { redirect_to(@computer) }
        format.xml { render :xml => @computer, :status => :created }
      else
        flash[:error] = "Failed to create #{@computer} computer object!"
        format.html { render :action => "new"}
      end
    end
  end

  def show
    @computer = Computer.find_for_show(params[:id])
    
    if @computer
      respond_to do |format|
        format.html
        format.manifest { render :text => @computer.to_plist}
        format.plist { render :text => @computer.to_plist}
        format.client_prefs { render :text => @computer.client_prefs.to_plist }
      end
    else
      #If the computer is not currently in the database, create a temp. computer with the correct mac address, and return a config
      @computer = Computer.new(:mac_address => params[:id])
      respond_to do |format|
        format.client_prefs { render :text => @computer.client_prefs.to_plist }
      end
    end
  end

  def edit
    @computer = Computer.unit(current_unit).find(params[:id])
  end

  def update
    @computer = Computer.unit(current_unit).find(params[:id])
    @computer_service = ComputerService.new(@computer,params[:computer])
    respond_to do |format|
      if @computer_service.save
        flash[:notice] = "#{@computer.name} was successfully updated."
        format.html { redirect_to(@computer) }
        format.xml  { head :ok }
      else
        flash[:error] = 'Could not update computer!'
        format.html { render :action => "edit" }
        format.xml  { render :xml => @computer.errors, :status => :unprocessable_entity }
      end
    end 
  end

  def destroy
    @computer = Computer.find(params[:id])
    
    if @computer.destroy
      flash[:notice] = "Computer was destroyed successfully"
    end
    
    respond_to do |format|
      format.html { redirect_to computers_path }
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
        format.html { redirect_to import_new_computer_path }
      elsif @computers.count > 0
        flash[:notice] = "#{@computers.count} of #{@total} computers imported into #{@computers.first.computer_group}"
        format.html { redirect_to computers_path }
      else
        flash[:warning] = "Zero computers were imported.  Did the ARD list have any members?"
        format.html { redirect_to computers_path }
      end
    end
  end
  
  # Allows a computer to checkin with the server, notifying it
  # of the last successful munki run.  May be extended in the future.
  def checkin
    @computer = Computer.find_for_show(params[:id])
    @computer.client_logs.build(:managed_software_update_log => params[:managed_software_update_log], 
                                :errors_log => params[:errors_log], 
                                :installs_log => params[:installs_log])
    @computer.save
    @computer.error_mailer.deliver if @computer.error_mailer_due?
        
    render :text => ''
  end
end
