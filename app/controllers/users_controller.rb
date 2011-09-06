class UsersController < ApplicationController  
  def index
    @users = User.all
  end
  
  def new
  end
  
  def create
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = "#{@user.username} was successfully created."
        format.html { redirect_to(users_path) }
      else
        flash[:error] = "Failed to create user!"
        format.html { render :action => "new"}
      end
    end
  end
  
  def show
  end
  
  def edit
  end
  
  def update
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = "#{@user.username} was successfully updated."
        format.html { redirect_to(@user) }
        format.xml  { head :ok }
      else
        flash[:error] = 'Could not update user!'
        format.html { render :action => "edit" }
      end
    end
  end
  
  def destroy
    respond_to do |format|
      if @user.destroy
        flash[:notice] = "#{@user.username} was successfully removed."
        format.html { redirect_to(users_path) }
      else
        format.html { render :action => "index" }
      end
    end
  end
  
  private
  def load_singular_resource
    action = params[:action].to_sym
    if [:show, :edit, :update, :destroy].include?(action)      
      @user = User.find_by_username(params[:id])
    elsif [:index, :new, :create].include?(action)
      @user = User.new
    end
  end
end
