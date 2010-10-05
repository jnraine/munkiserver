class Computer < ActiveRecord::Base
  magic_mixin :manifest
  
  belongs_to :computer_model
  belongs_to :computer_group
  
  has_many :client_logs
  
  # Validations
  validate :computer_model
  # mac_address attribute must look something like ff:12:ff:34:ff:56
  validates_format_of :mac_address, :with => /^([0-9a-f]{2}(:|$)){6}$/
  
  # before_save :require_computer_group
  
  # Maybe I shouldn't be doing this
  include ActionView::Helpers
  
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
  
  # For will_paginate gem.  Sets the default number of records per page.
  def self.per_page
    10
  end

  # Make sure this computer is assigned a computer group
  # if it isn't, assign the default computer group
  # No longer used, instead, trying to not assume a computer has a group
  def require_computer_group
    self.computer_group_id = ComputerGroup.default(self.unit).id if self.computer_group_id.nil?
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
  
  # Extended from manifest magic_mixin, adds mac_address matching
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
  
  # Return the latest instance of ClientLog
  def last_run
    client_logs.last
  end
  
  # Returns, in words, the time since last run
  def time_since_last_run
    unless last_run.nil?
      time_ago_in_words(last_run.created_at) + " ago"
    else
      "Never"
    end
  end
  
  # Get most recent logs in reverse chronological order
  # Default to 15 logs
  def recent_client_logs(num = 15)
    ClientLog.where(:computer_id => id).limit(num).order("created_at desc")
  end
end
