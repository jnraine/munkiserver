include SweeperHelper

class PackageSweeper < ActionController::Caching::Sweeper
  observe Package


  def before_save(package)
    expire_old_catalog(package)
    true
  end
  
  def before_destroy(package)
    expire_old_catalog(package)
    true
  end
  
  def after_save(package)
    expire_new_catalog(package)
  end

  def after_destroy(package)
    expire_new_catalog(package)
  end

  private
  
  def expire_old_catalog(package)
    #Expire the old unit, if it has changed
    old_unit_id = package.changed_attributes["unit_id"]
    old_unit_id ||=  package.unit_id

    #Expire the old environment, if it has changed      
    old_environment_id = package.changed_attributes["environment_id"]
    old_environment_id ||= package.environment_id
    
    Rails.logger.info "CACHE: Expiring the catalogs for #{catalog_cache_key_generator(:unit_id => old_unit_id, :environment_id => old_environment_id)}"
    Rails.cache.delete catalog_cache_key_generator(:unit_id => old_unit_id, :environment_id => old_environment_id)
  end
  
  def expire_new_catalog(package)
    #Expire the new catalog
    Rails.logger.info "CACHE: Expiring the catalogs for #{catalog_cache_key_generator(:unit_id => package.unit_id, :environment_id => package.environment_id)}"
    Rails.cache.delete catalog_cache_key_generator(:unit_id => package.unit_id, :environment_id => package.environment_id)
  end
end