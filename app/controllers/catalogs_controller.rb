#Helper functions to consolidate cache_key_generation logic
include SweeperHelper

class CatalogsController < ApplicationController
  skip_before_filter :load_singular_resource
  
  def show
    unit_id = params[:unit_environment].split("-")[0]
    environment_name = params[:unit_environment].split("-")[1]
    environment_id = Environment.where(:name => environment_name).first.id
    
    #Generate a cache_key for this particular unit/environment catalog
    cache_key = catalog_cache_key_generator(:unit_id => unit_id, :environment_id => environment_id)

    respond_to do |format|
      #Fetch the content from the cache, if available.  If not, generate it using the Catalog.generate method
      format.plist { render :text => Rails.cache.fetch(cache_key) {
          Rails.logger.info "CACHE: Geneterating catalog for #{cache_key}"
          @catalog = Catalog.generate(unit_id, environment_id)
          @catalog.to_plist.gsub(/\r\n?/, "\n")
        }
      }
    end
  end
end
