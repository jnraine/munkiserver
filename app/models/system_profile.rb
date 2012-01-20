class SystemProfile < ActiveRecord::Base
  belongs_to :computer
  
  has_many :sp_printers

  # Include helpers
  include ActionView::Helpers

  scope :unused, where(:computer_id => nil)
  
  # Formats a system profiler plist file object into a ruby 
  # hash that can be used to create a new SystemProfile record.
  def self.format_system_profiler_plist(system_profiler_plist_file)
    xml_string = system_profiler_plist_file.read if system_profiler_plist_file.present?
    self.format_system_profiler_hash(Plist.parse_xml(xml_string.to_utf8)) if xml_string.present?
  end
  
  # Creates a SystemProfile object based on a system profiler 
  # plist ruby hash.
  def self.import(profiler_plist_file)
    self.create(self.format_system_profiler_plist(profiler_plist_file))
  end
  
  # Formats the output of system_profiler into a hash of
  # attributes that can be used to create a SystemProfile
  # record.
  def self.format_system_profiler_hash(system_profiler_hash)
    attributes = {}
    system_profiler_hash.each do |data_set|
      data_type = data_set["_dataType"].underscore if data_set["_dataType"].present?
      format_method_name = "format_#{data_type}"
      if self.respond_to?(format_method_name) and data_type.present?
        attributes = attributes.merge(self.send("format_#{data_type}",data_set))
      else
        logger.debug "Unable to format #{data_type}: format method not defined or data_type unknown"
      end
    end
    attributes
  end

  # Format SPHardwareDataType from system_profiler into
  # attributes for creating a SystemProfile record.
  def self.format_sp_hardware_data_type(data_set)
    # List of allowed keys
    allowed_keys = ["cpu_type","current_processor_speed","l2_cache_core","l3_cache",
                    "machine_model","machine_name","number_processors","physical_memory",
                    "platform_uuid","serial_number"]
    # Retrieve the proper hash
    items = data_set["_items"] if data_set.present?
    item_0 = items.first if items.present?
    # Format the keys
    f_item_0 = underscore_keys(item_0)
    # Delete elements with keys not listed in allowed_keys
    f_item_0.delete_if do |k,v|
      if !allowed_keys.include?(k)
        logger.debug "Removing #{k} key from SPHardwareDataType data set"
        true
      end
    end
    # Return hash
    f_item_0
  end
  
  # Format SPSoftwareDataType from system_profiler into
  # attributes for creating a SystemProfile record.
  def self.format_sp_software_data_type(data_set)
    # List of allowed keys
    allowed_keys = ["os_64bit_kernel_and_kexts","boot_volume","kernel_version","local_host_name","os_version","uptime","user_name"]
    # Retrieve the proper hash
    items = data_set["_items"] if data_set.present?
    item_0 = items.first if items.present?
    # Format the keys
    f_item_0 = underscore_keys(item_0)
    # Fix special cases
    f_item_0["os_64bit_kernel_and_kexts"] = f_item_0.delete("64bit_kernel_and_kexts")
    # Delete elements with keys not listed in allowed_keys
    f_item_0.delete_if do |k,v|
      if !allowed_keys.include?(k)
        logger.debug "Removing #{k} key from SPSoftwareDataType data set"
        true
      end
    end
    # Return hash
    f_item_0
  end
  
  # Calls underscore method on each hash key string
  def self.underscore_keys(hash)
    new_hash = {}
    hash.each do |k,v|
      new_hash[k.underscore] = v
    end
    new_hash
  end
  
  def self.format_sp_printers_data_type(data_set)
    # Retrieve the proper array
    printers = data_set["_items"] if data_set.present?
    f_printers = printers.map {|p_hash| SpPrinter.create_from_system_profiler_printer_hash(p_hash) }
    {"sp_printers" => f_printers.compact}
  end
end
