class UsersController < ApplicationController  
  load_resource :find_by => :username
  authorize_resource
  
  def index
  end
  
  def new
  end
  
  def create    
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
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
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
