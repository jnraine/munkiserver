class CatalogsController < ApplicationController
  skip_before_filter :load_singular_resource
  skip_before_filter :require_valid_unit
  
  def show
    @catalog = Catalog.generate(params[:unit_id],params[:environment_name])
    respond_to do |format|
      format.plist { render :text => @catalog.to_plist }
    end
  end
end