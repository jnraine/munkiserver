include SweeperHelper

class EnvironmentSweeper < ActionController::Caching::Sweeper
  observe Environment

  def after_save(environment)
    expire_catalog(environment)
  end

  def after_destroy(environment)
    expire_catalog(environment)
  end

  private
    
    def expire_catalog(environment)
      # Expire the catalogs for all environments in this unit
      Unit.all.each { |unit|
        Rails.logger.info "CACHE: Expiring the catalogs for #{catalog_cache_key_generator(:unit_id => unit.id, :environment_id => environment.id}"
        Rails.cache.delete catalog_cache_key_generator(:unit_id => unit.id, :environment_id => environment.id)
      }
    end

end