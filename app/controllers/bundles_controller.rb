class BundlesController < ApplicationController
  authorize_resource
    
  def index
    @bundles = Bundle.unit(current_unit)
    
    respond_to do |format|
      format.html
    end
  end

  def create
    @bundle = Bundle.new(params[:bundle])
    @bundle.unit = current_unit
    
    respond_to do |format|
      if @bundle.save
        flash[:notice] = "Bundle successfully saved"
        format.html { redirect_to bundles_path }
      else
        flash[:error] = "Bundle failed to save!"
        format.html { render new_bundle_path }
      end
    end
  end

  def destroy
    @bundle = Bundle.find_for_show(params[:unit], params[:id])
    
    if @bundle.destroy
      flash[:notice] = "Bundle was destroyed successfully"
    end
    
    respond_to do |format|
      format.html { redirect_to bundles_path }
    end
  end

  def edit
    @bundle = Bundle.find_for_show(params[:unit], params[:id])
    @environment_id = params[:environment_id] if params[:environment_id].present?
  end

  def update
    @bundle = Bundle.find_for_show(params[:unit], params[:id])
    
    respond_to do |format|
      if @bundle.update_attributes(params[:bundle])
        flash[:notice] = "#{@bundle} was successfully updated."
        format.html { redirect_to bundle_path(@bundle.unit, @bundle) }
      else
        flash[:error] = "Could not update bundle!"
        format.html { redirect_to edit_bundle(@bundle.unit, @bundle) }
      end
    end
  end

  def new
    @bundle = Bundle.new
    @bundle.unit = current_unit
  end

  def show
    @bundle = Bundle.find_for_show(params[:unit], params[:id])
    
    respond_to do |format|
      if @bundle.present?
        format.html
        format.manifest { render :text => @bundle.to_plist }
        format.plist { render :text => @bundle.to_plist }
      else
        format.html{ render :file => "#{Rails.root}/public/404.html", :layout => false }
      end
    end
  end
  
  def environment_change
    if params[:bundle_id] == "new"
      @bundle = Bundle.new({:unit_id => current_unit.id})
    else
      @bundle = Bundle.find(params[:bundle_id])
    end
    
    @environment_id = params[:environment_id] if params[:environment_id].present?
    
    respond_to do |format|
      format.js
    end
  end
end
