class Computer < ActiveRecord::Base
  magic_mixin :manifest
  
  belongs_to :computer_model
  belongs_to :computer_group
  
  has_many :client_logs
  
  # Validations
  validate :computer_model
  # mac_address attribute must look something like ff:12:ff:34:ff:56
  validates_format_of :mac_address, :with => /^([0-9a-f]{2}(:|$)){6}$/
  validates_uniqueness_of :mac_address,:name
  
  # before_save :require_computer_group
  
  # Maybe I shouldn't be doing this
  include ActionView::Helpers
  
  # Computers are considered dormant when they haven't checked in for 
  # longer than value of dormant_interval.  Value stored in method
  # instead of constant to ensure the value is up-to-date at all times
  def self.dormant_interval
    7.days.ago
  end
  
  # Alias the computer_model icon to this computer
  def icon
    computer_model.icon
  end
  
  # For will_paginate gem.  Sets the default number of records per page.
  def self.per_page
    10
  end

  # Filters dormant computers from Computer model.  Because this method
  # must filter based on ClientLog relationships, this method does not
  # return an ActiveRecord::Relation instance.  If you pass a unit, it 
  # return dormant computers from that unit only.
  def self.dormant(unit = nil)
    dormant = []
    computers = Computer.unit(unit) if unit.present?
    computers ||= Computer.all
    computers.each do |computer|
      if computer.dormant?
        dormant << computer
      end
    end
    dormant
  end

  # Examines the client logs of a computer to determine if it has been dormant
  def dormant?
    (self.last_successful_run.nil? and self.created_at < self.class.dormant_interval) or (self.last_successful_run.created_at < self.class.dormant_interval)
  end

  # Make sure this computer is assigned a computer group
  # if it isn't, assign the default computer group
  # No longer used, instead, trying to not assume a computer has a group
  def require_computer_group
    self.computer_group_id = ComputerGroup.default(self.unit).id if self.computer_group_id.nil?
  end

  # Moved this method to unit_member so it was only in one place (also present in Package class)
  # def catalogs
  #   c = []
  #   environments.each do |env|
  #     c << "#{unit.id}_#{env.name}.plist"
  #   end
  #   c
  # end

  # Returns a hash representing the ManagedInstalls.plist
  # that should be placed in /Library/Preferences on this client
  def client_prefs
    port = ":3000" if Rails.env == "development"
    url = "http://" + `hostname`.chomp + port.to_s
    prefs = { :DaysBetweenNotifications => 1,
              :InstallAppleSoftwareUpdates => true,
              :LogFile => "/Library/Managed Installs/Logs/ManagedSoftwareUpdate.log",
              :LoggingLevel => 1,
              :UseClientCertificate => false }
    if self.id == nil
      #client computer doesn't exist in database currently
      prefs.merge!({:AppleSoftwareUpdatesOnly => true})
    else
      #client does exist
      prefs.merge!({:ClientIdentifier => client_identifier,
                    :ManagedInstallsDir => "/Library/Managed Installs",
                    :ManifestURL => url,
                    :SoftwareRepoURL => url})
    end

    prefs
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
    if last_run.present?
      time_ago_in_words(last_run.created_at) + " ago"
    else
      "never"
    end
  end
  
  def time_since_last_successful_run
    if last_successful_run.present?
      time_ago_in_words(last_successful_run.created_at) + " ago"
    else
      "never"
    end
  end
  
  def last_successful_run
    client_logs.successful.last if client_logs.successful.present?
  end
  
  # Get most recent logs in reverse chronological order
  # Default to 15 logs
  def recent_client_logs(num = 15)
    ClientLog.where(:computer_id => id).limit(num).order("created_at desc")
  end
  
  # Check the client logs and determine if this item has been installed or not
  def installed?(package)
    name = package.name
    version = package.version
    log = last_managed_software_update_log
    log.present? and log.match(/#{Regexp.escape(name)} version (#{Regexp.escape(version)}) \(or newer\) is already installed/).present?
  end
  
  # Gets the last managed software update log (nil if none)
  def last_managed_software_update_log
    logs = client_logs.last
    logs.managed_software_update_log unless logs.nil?
  end
  
  # An error report for this computer is due based on various parameters
  # => Last successful run was longer than 1 day ago
  # => Last successful run was updated longer than 1 day ago
  # => Error logs are present on the last run
  def error_mailer_due?
    last_successful_run.created_at < 1.days.ago and 
    last_successful_run.updated_at < 1.days.ago and
    last_run.errors_log.present?
  end
  
  # Send error report for this computer.  Touches last successful run log
  # to indicate when the last error report was sent
  def error_mailer
    last_successful_run.touch
    AdminMailer.computer_error(self).deliver
  end
  
  # Gets an array of users responsible for this computer
  def admins
    unit.members if unit.present?
  end
end
