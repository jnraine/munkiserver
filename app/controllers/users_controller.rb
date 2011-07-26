class UsersController < ApplicationController
  before_filter :super_user?
  filter_access_to :all, :attribute_check => true
  
  
  
  def index
    @users = User.all
  end
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new(params[:user])
    
    respond_to do |format|
      if @user.save
        flash[:notice] = "#{@user.username} was successfully created."
        format.html { redirect_to(users_path) }
        format.xml { render :xml => @user, :status => :created }
      else
        flash[:error] = "Failed to create #{@user.username}!"
        format.html { render :action => "new"}
      end
    end
  end
  
  def show
    @user = User.find_by_username(params[:id])
  end
  
  def edit
    @user = User.find_by_username(params[:id])
  end
  
  def update
    @user = User.find_by_username(params[:id])
    
    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = "#{@user.username} was successfully updated."
        format.html { redirect_to(@user) }
        format.xml  { head :ok }
      else
        flash[:error] = 'Could not update user!'
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @user = User.find_by_username(params[:id])
    username = @user.username
    
    respond_to do |format|
      if @user.destroy
        flash[:notice] = "#{@user.username} was successfully removed."
        format.html { redirect_to(users_path) }      
        format.xml { head :ok }
      else
        format.html { render :action => "index" }
      end
    end
  end
end
