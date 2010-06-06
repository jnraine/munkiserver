class Computer < ActiveRecord::Base
  magic_mixin :manifest
  
  belongs_to :computer_model
  belongs_to :computer_group
  
  validate :computer_model
  
  # Getter for virtual attribute hostname
  def hostname
    name
  end
  
  # Setting for virtual attribute hostname
  def hostname=(value)
    name = value
  end
  
  # Alias the computer_model icon to this computer
  def icon
    computer_model.icon
  end
  
  # For will_paginate gem
  def self.per_page
    10
  end

  def catalogs
    c = []
    environments.each do |env|
      c << "#{unit.id}-#{env.name}.plist"
    end
    c
  end

  # Returns a hash representing the ManagedInstalls.plist
  # that should be placed in /Library/Preferences on this client
  def client_prefs
    port = ":3000" if Rails.env == "development"
    url = "http://" + `hostname`.chomp + port.to_s
    { :ClientIdentifier => client_identifier,
      :DaysBetweenNotifications => 1,
      :InstallAppleSoftwareUpdates => true,
      :LogFile => "/Library/Managed Installs/Logs/ManagedSoftwareUpdate.log",
      :LoggingLevel => 1,
      :ManagedInstallsDir => "/Library/Managed Installs",
      :ManifestURL => url,
      :SoftwareRepoURL => url,
      :UseClientCertificate => false }
  end
  
  # Extend manifest by removing name attribute and adding the catalogs
  def serialize_for_plist
    h = serialize_for_plist_super
    h.delete(:name)
    h[:catalogs] = catalogs
    h
  end
  
  # Extended from manifest magic_mixin, addess mac_address matching
  def self.find_for_show(s)
    record = find_for_show_super(s)
    # For mac_address
    record ||= self.where(:mac_address => s).first
    # Return record
    record
  end
  
  def client_identifier
    self.class.to_s.tableize + "/" + mac_address + ".plist"
  end
  
  # Validates the presence of a computer model
  # and puts in the default model otherwise
  def presence_of_computer_model
    if computer_model.nil?
      computer_model = ComputerModel.default
    end
  end
end
