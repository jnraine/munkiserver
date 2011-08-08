class UserSettingsController < ApplicationController
  authorize_resource
  
  def edit
    @user_setting = UserSetting.find(params[:id])
  end
  
  def update
    @user_setting = UserSetting.find(params[:id])
    respond_to do |format|
      if @user_setting.update_attributes(params[:user_setting])
        flash[:notice] = "Settings successfully updated."
        format.html { redirect_to user_path(User.where(:id => @user_setting.id).first) }
        format.xml  { head :ok }
      else
        flash[:error] = 'Could not update settings!'
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user_setting.errors, :status => :unprocessable_entity }
      end
    end
  end
end