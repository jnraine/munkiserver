class BundlesController < ApplicationController
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
    @bundle = Bundle.find(params[:id])
    
    if @bundle.destroy
      flash[:notice] = "Bundle was destroyed successfully"
    end
    
    respond_to do |format|
      format.html { redirect_to bundles_path }
    end
  end

  def edit
    @bundle = Bundle.find(params[:id])
  end

  def update
    @bundle = Bundle.unit(current_unit).find(params[:id])
    @manifest_service = ManifestService.new(@bundle,params[:bundle])
    
    respond_to do |format|
      if @manifest_service.save
        flash[:notice] = "Bundle was successfully updated."
        format.html { redirect_to bundle_path(@bundle) }
        format.xml { head :ok }
      else
        flash[:error] = "Could not update bundle!"
        format.html { redirect_to edit_bundle(@bundle) }
        format.xml { render :xml => @bundle.errors, :status => :unprocessable_entity }
      end
    end
  end

  def new
    @bundle = Bundle.new
  end

  def show
    @bundle = Bundle.find_for_show(params[:id])
    
    respond_to do |format|
      format.html
      format.manifest { render :text => @bundle.to_plist }
      format.plist { render :text => @bundle.to_plist }
    end
  end
end
