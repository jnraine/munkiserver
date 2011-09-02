class ManagedInstallReport < ActiveRecord::Base
  belongs_to :computer

  scope :error_free, where(:munki_errors => [].to_yaml)

  serialize :munki_errors, Array
  serialize :install_results, Array
  serialize :installed_items, Array
  serialize :items_to_install, Array
  serialize :items_to_remove, Array
  serialize :machine_info # Hash
  serialize :managed_installs, Array
  serialize :problem_installs, Array
  serialize :removal_results, Array
  serialize :removed_items, Array
  serialize :munki_warnings, Array
  serialize :managed_installs_list, Array
  serialize :managed_uninstalls_list, Array
  serialize :managed_updates_list, Array
  
  scope :since, lambda {|timestamp| where("created_at > ?", timestamp) }
  scope :has_errors, where("munki_errors != ?", [].to_yaml)

  TABLE_ATTRIBUTES = ["items_to_install","items_to_remove","managed_installs"]
  LOG_ATTRIBUTES = ["munki_errors","munki_warnings","install_results", "removal_results"]
  # Attributes not accounted for: installed_items, problem_installs, managed_installs_list, managed_uninstalls_list, managed_updates_list

  # Include helpers
  include ActionView::Helpers
  
  # Creates a ManagedInstallReport object based on a plist file
  def self.import_plist(file)
    xml_string = file.read if file.present?
    self.import(Plist.parse_xml(xml_string)) if xml_string.present?
  end
  
  def self.format_report_plist(report_plist_file)
    xml_string = report_plist_file.read if report_plist_file.present?
    self.format_report_hash(Plist.parse_xml(xml_string.to_utf8)) if xml_string.present?
  end
  
  def self.format_report_hash(report_hash)
    # Escape CamelCased attributes
    report_hash = underscore_keys(report_hash)
    # Re-key dangerous attributes
    report_hash["munki_errors"] = report_hash.delete("errors")
    report_hash["munki_warnings"] = report_hash.delete("warnings")
    # Delete invalid keys
    valid_attributes = self.new.attributes.keys
    report_hash.delete_if do |k| 
      if !valid_attributes.include?(k)
        logger.debug "Invalid key (#{k}) found while creating #{self.class.to_s} object from report hash"
        true
      end
    end
    report_hash
  end
  
  # Creates a ManagedInstallReport object based on a ManagedInstallReport.plist ruby hash
  def self.import(report_hash)
    report_hash = self.format_report_hash(report_hash)
    # Create object
    self.create(report_hash)
  end
  
  # Calls underscore method on each hash key string
  def self.underscore_keys(hash)
    new_hash = {}
    hash.each do |k,v|
      new_hash[k.underscore] = v
    end
    new_hash
  end
  
  # Time since this log was created, in words
  def time_since_created_at_in_words
    time_ago_in_words(self.created_at) + " ago"
  end
  
  # Retrieve information from machine_info attribute.  Always
  # returns a reasonable string.
  def get_machine_info(key)
    value = machine_info[key] if machine_info.present?
    
    if value.present?
      value
    else
      ""
    end
  end
  
  def errors?
    munki_errors.present? or problem_installs.present?
  end
  
  def warnings?
    munki_warnings.present?
  end
  
  def ok?
    issues? == false
  end
  
  def issues?
    errors? or warnings?
  end
  
  # Text value of option tag text
  def option_text
    s = ""
    if created_at > 12.hours.ago
			s += time_ago_in_words(created_at) + " ago"
		else
		  s += created_at.getlocal.to_s(:readable_detail)
		end
		s += "*" if issues?
		s
  end
  
  # Get the unit for this managed install report based on the computer
  def unit
    Unit.find(computer.unit_id) if computer.present?
  end

  # Get the computer this managed install report belong to
  def computer
    Computer.find_by_hostname(self.machine_info["hostname"]) if machine_info["hostname"].present?
  end
end

