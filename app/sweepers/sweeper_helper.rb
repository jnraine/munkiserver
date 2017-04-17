# Sweeper helper methods.  Ideally will be used for various types of key generators.
# My hope is that this would be the central place for cache_key generators to live so that
# we are following a similar methodology for cache_keys and not overlapping

module SweeperHelper
  #Generate a cache key for the Catalog _model_
  def catalog_cache_key_generator(options = {})
    # cache_key = { :type => :catalog, :unit => options[:unit_id], :environment_id => options[:environment_id]}
    cache_key = "catalog/#{options[:unit_id]}/#{options[:environment_id]}"
    Rails.logger.info "CACHE: Generating unique cache key: #{cache_key}"
    cache_key
  end
end