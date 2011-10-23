include SweeperHelper

class UnitSweeper < ActionController::Caching::Sweeper
  observe Unit

  def after_save(unit)
    expire_catalog(unit)
  end

  def after_destroy(unit)
    expire_catalog(unit)
  end

  private

  # Expire the catalogs for all environments in this unit
  def expire_catalog(unit)
    Environment.all.each { |environment|
      Rails.logger.info "CACHE: Expiring the catalogs for #{catalog_cache_key_generator(:unit_id => unit.id, :environment_id => environment.id)}"
      Rails.cache.delete catalog_cache_key_generator(:unit_id => unit.id, :environment_id => environment.id)
    }
  end

end