class ComputerGroupsController < ApplicationController
  helper_method :sort_column, :sort_direction

  def index
    @computer_groups = ComputerGroup.unit(current_unit).order_alphabetical
    
    respond_to do |format|
      format.html
    end
  end

  def create
    respond_to do |format|
      if @computer_group.update_attributes(params[:computer_group])
        flash[:notice] = "Computer group successfully saved"
        format.html { redirect_to computer_groups_path(@computer_group.unit) }
      else
        flash[:error] = "Computer group failed to save!"
        format.html { render new_computer_group_path(@computer_group.unit) }
      end
    end
  end

  def destroy
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
    @environment_id = params[:environment_id] if params[:environment_id].present?
  end

  def update
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
  end

  def show
    respond_to do |format|
      if @computer_group.present?
        format.html
        format.manifest { render :text => @computer_group.to_plist }
        format.plist { render :text => @computer_group.to_plist }
      else
        format.html{ render :file => "#{Rails.root}/public/404.html", :layout => false }
      end
    end
  end
  
  def environment_change    
    @environment_id = params[:environment_id] if params[:environment_id].present?
    
    respond_to do |format|
      format.js
    end
  end
  
  private
  def load_singular_resource
    action = params[:action].to_sym
    if [:show, :edit, :update, :destroy].include?(action)      
      @computer_group = ComputerGroup.unit(current_unit).find_for_show(params[:unit_shortname], CGI::unescape(params[:id]))
    elsif [:index, :new, :create].include?(action)      
      @computer_group = ComputerGroup.new({:unit_id => current_unit.id})
    elsif [:environment_change].include?(action)      
      if params[:computer_group_id] == "new"
        @computer_group = ComputerGroup.new({:unit_id => current_unit.id})
      else
        @computer_group = ComputerGroup.find(params[:computer_group_id])
      end
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
