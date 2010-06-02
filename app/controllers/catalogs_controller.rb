class CatalogsController < ApplicationController
  def show
    @catalog = Catalog.generate(params[:unit_id],params[:environment_name])
    
    respond_to do |format|
      format.plist { render :text => @catalog.to_plist }
    end
  end
end