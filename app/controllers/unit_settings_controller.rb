class UnitSettingsController < ApplicationController
  def edit
    @unit_setting = UnitSetting.where(:unit_id => Unit.where(:name => params[:id]).first.id).first
  end
  
  def update
    @unit_setting = UnitSetting.where(:unit_id => Unit.where(:name => params[:id]).first.id).first
    respond_to do |format|
      if @unit_setting.update_attributes(params[:unit_setting])
        flash[:notice] = "Settings successfully updated."
        format.html { redirect_to unit_path(Unit.where(:name => params[:id]).first) }
        format.xml  { head :ok }
      else
        flash[:error] = 'Could not update settings!'
        format.html { render :action => "edit" }
        format.xml  { render :xml => @unit_setting.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def show
    @unit_setting = UnitSetting.find_by_unit_id(Unit.find_by_name(params[:id]).id)
    respond_to do |format|
      format.html
    end
  end
end