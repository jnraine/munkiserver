class ComputerGroupsController < ApplicationController
  before_filter :require_valid_unit
  
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
        format.html { redirect_to computer_groups_path(@computer_group.unit) }
      else
        flash[:error] = "Computer group failed to save!"
        format.html { render new_computer_group_path(@computer_group.unit) }
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
      format.html { redirect_to computer_groups_path(@computer_group.unit) }
    end
  end

  def edit
    @computer_group = ComputerGroup.find_for_show(params[:id])
    @environment_id = params[:environment_id] if params[:environment_id].present?
  end

  def update
    @computer_group = ComputerGroup.unit(current_unit).find_for_show(CGI::unescape(params[:id]))
    
    respond_to do |format|
      if @computer_group.update_attributes(params[:computer_group])
        flash[:notice] = "#{@computer_group} was successfully updated."
        format.html { redirect_to computer_group_path(@computer_group.unit, @computer_group) }
      else
        flash[:error] = "Could not update computer group!"
        format.html { redirect_to edit_computer_group(@computer_group.unit, @computer_group) }
      end
    end
  end

  def new
    @computer_group = ComputerGroup.new
    @computer_group.unit = current_unit
  end

  def show
    @computer_group = ComputerGroup.find_for_show(params[:id])
    
    respond_to do |format|
      format.html
      format.manifest { render :text => @computer_group.to_plist }
      format.plist { render :text => @computer_group.to_plist }
    end
  end
  
  def environment_change
    if params[:computer_group_id] == "new"
      @computer_group = ComputerGroup.new({:unit_id => current_unit.id})
    else
      @computer_group = ComputerGroup.find(params[:computer_group_id])
    end
    
    @environment_id = params[:environment_id] if params[:environment_id].present?
    
    respond_to do |format|
      format.js
    end
  end
end
