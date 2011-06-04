class ComputerGroupsController < ApplicationController
  def index
    @computer_groups = ComputerGroup.unit(current_unit)
    
    respond_to do |format|
      format.html
    end
  end

  def create
    @computer_group = ComputerGroup.new(params[:computer_group])
    @computer_group.unit = current_unit
    
    respond_to do |format|
      if @computer_group.save
        flash[:notice] = "Computer group successfully saved"
        format.html { redirect_to computer_groups_path }
      else
        flash[:error] = "Computer group failed to save!"
        format.html { render new_computer_group_path }
      end
    end
  end

  def destroy
    @computer_group = ComputerGroup.find_for_show(CGI::unescape(params[:id]))
    
    begin
      if @computer_group.destroy
        flash[:notice] = "Computer group was destroyed successfully"
      else
        flash[:error] = "Failed to remove computer group!"
      end
    rescue ComputerGroupException
      flash[:error] = "You cannot remove the last computer group from this unit!"
    end
    
    respond_to do |format|
      format.html { redirect_to computer_groups_path }
    end
  end

  def edit
    @computer_group = ComputerGroup.find_for_show(params[:id])
  end

  def update
    @computer_group = ComputerGroup.unit(current_unit).find_for_show(CGI::unescape(params[:id]))
    @manifest_service = ManifestService.new(@computer_group,params[:computer_group])
    
    respond_to do |format|
      if @manifest_service.save
        flash[:notice] = "Computer group was successfully updated."
        format.html { redirect_to computer_group_path(@computer_group) }
        format.xml { head :ok }
      else
        flash[:error] = "Could not update computer group!"
        format.html { redirect_to edit_computer_group(@computer_group) }
        format.xml { render :xml => @computer_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  def new
    @computer_group = ComputerGroup.new
  end

  def show
    @computer_group = ComputerGroup.find_for_show(params[:id])
    
    respond_to do |format|
      format.html
      format.manifest { render :text => @computer_group.to_plist }
      format.plist { render :text => @computer_group.to_plist }
    end
  end
end
