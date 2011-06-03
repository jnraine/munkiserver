class SpPrinter < ActiveRecord::Base
  belongs_to :system_profile
  
  # Formats a hash from a system_profiler printer and returns
  # an unsaved SpPrinter object
  def self.create_from_system_profiler_printer_hash(p_hash)
    # List of allowed keys
    allowed_keys = self.new.attributes.keys
    # Format the keys
    f_p_hash = SystemProfile.underscore_keys(p_hash)
    # Fix special cases
    f_p_hash["name"] = f_p_hash.delete("_name")
    # Delete elements with keys not listed in allowed_keys
    f_p_hash.delete_if do |k| 
      if !allowed_keys.include?(k)
        logger.debug "Removing #{k} key from system profiler printer hash"
        true
      end
    end
    SpPrinter.create(f_p_hash)
  end
end
