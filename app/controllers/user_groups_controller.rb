class UserGroupsController < ApplicationController
  def index
    @user_groups = UserGroup.where(:unit_id => current_unit.id)
    
    respond_to do |format|
      format.html
    end
  end

  def create
    respond_to do |format|
      if @user_group.update_attributes(params[:user_group])
        flash[:notice] = "Computer group successfully saved"
        format.html { redirect_to user_groups_path(@user_group.unit) }
      else
        flash[:error] = "Computer group failed to save!"
        format.html { render new_user_group_path(@user_group.unit) }
      end
    end
  end

  def destroy
    if @user_group.destroy
      flash[:notice] = "Computer group was destroyed successfully"
    else
      flash[:error] = "Failed to remove computer group!"
    end
    
    respond_to do |format|
      format.html { redirect_to user_groups_path(@user_group.unit) }
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @user_group.update_attributes(params[:user_group])
        flash[:notice] = "#{@user_group} was successfully updated."
        format.html { redirect_to edit_user_group_path(@user_group.unit, @user_group) }
      else
        flash[:error] = "Could not update computer group!"
        format.html { redirect_to edit_user_group(@user_group.unit, @user_group) }
      end
    end
  end

  def new
  end
  
  private
  def load_singular_resource
    action = params[:action].to_sym
    if [:show, :edit, :update, :destroy].include?(action)      
      @user_group = UserGroup.where_unit(current_unit).find_for_show(current_unit, CGI::unescape(params[:id]))
    elsif [:index, :new, :create].include?(action)      
      @user_group = UserGroup.new({:unit_id => current_unit.id})
    else
      raise Exception.new("Unable to load singular resource for #{action} action in #{params[:controller]} controller.")
    end
  end
  
end
