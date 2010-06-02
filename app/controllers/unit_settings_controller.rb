class UnitSettingsController < ApplicationController
  def edit
    @unit_setting = UnitSetting.find(params[:id])
  end
  
  def update
    @unit_setting = UnitSetting.find(params[:id])
    
    respond_to do |format|
      if @unit_setting.update_attributes(params[:unit_setting])
        flash[:notice] = "Settings successfully updated."
        format.html { redirect_to(@unit_setting.unit) }
        format.xml  { head :ok }
      else
        flash[:error] = 'Could not update settings!'
        format.html { render :action => "edit" }
        format.xml  { render :xml => @unit_setting.errors, :status => :unprocessable_entity }
      end
    end
  end
end