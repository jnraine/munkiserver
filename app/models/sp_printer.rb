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
# == Schema Information
#
# Table name: sp_printers
#
#  id                   :integer         not null, primary key
#  name                 :string(255)
#  cupsversion          :string(255)
#  default              :string(255)
#  driverversion        :string(255)
#  fax                  :string(255)
#  ppd                  :string(255)
#  ppdfileversion       :string(255)
#  printserver          :string(255)
#  psversion            :string(255)
#  scanner              :string(255)
#  scanner_uuid         :string(255)
#  scannerappbundlepath :string(255)
#  scannerapppath       :string(255)
#  status               :string(255)
#  uri                  :string(255)
#  system_profile_id    :integer
#  created_at           :datetime
#  updated_at           :datetime
#

