class Computer < ActiveRecord::Base
  magic_mixin :manifest
  # magic_mixin :client_pref
  
  belongs_to :computer_model
  belongs_to :computer_group
  
  has_one :system_profile, :dependent => :destroy, :autosave => true
  has_one :warranty, :dependent => :destroy, :autosave => true
  has_many :client_logs
  has_many :managed_install_reports
  
  # Validations
  validate :computer_model
  validates_format_of :mac_address, :with => /^([0-9a-f]{2}(:|$)){6}$/
  # validates_format_of :name, :with => /^[a-zA-Z0-9-]+$/, :message => "must only contain alphanumeric and hyphens characters"
  validates_uniqueness_of :mac_address
  
  # Maybe I shouldn't be doing this
  include ActionView::Helpers
  
  # Computers are considered dormant when they haven't checked in for 
  # longer than value of dormant_interval.  Value stored in method
  # instead of constant to ensure the value is up-to-date at all times
  def self.dormant_interval
    7.days.ago
  end
  
  # Overwrite computer_model association method to return 
  # computer model based on system_profile
  def computer_model
    model = ComputerModel.where(:name => system_profile.machine_model).first if system_profile.present?
    model ||= ComputerModel.find(computer_model_id) if computer_model_id.present?
    model ||= ComputerModel.default
  end
  
  def computer_group_options_for_select(unit,environment_id = nil)
    environment = Environment.where(:id => environment_id).first
    environment ||= self.environment
    environment ||= Environment.start
    ComputerGroup.unit_and_environment(unit, environment).map {|cg| [cg.name,cg.id] }
  end

  # Alias the computer_model icon to this computer
  def icon
    computer_model.icon
  end
  
  # Returns a hash representing the ManagedInstalls.plist
    # that should be placed in /Library/Preferences on this client
    def client_prefs
      url = ActionMailer::Base.default_url_options[:host]
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
    # (self.last_successful_run.nil? and self.created_at < self.class.dormant_interval) or (self.last_successful_run.created_at < self.class.dormant_interval)
    false
  end
  
  # Extend manifest by removing name attribute and adding the catalogs
  def serialize_for_plist
    h = serialize_for_plist_super
    h.delete(:name)
    h[:catalogs] = catalogs
    h
  end
  
  # Extended from manifest magic_mixin, adds mac_address matching
  def self.find_for_show(unit, id)
    record = find_for_show_super(unit, id)
    # For mac_address
    record ||= self.where(:mac_address => id).first
    # Return record
    record
  end

  def client_identifier
    mac_address + ".plist"
  end
  
  # Validates the presence of a computer model
  # and puts in the default model otherwise
  def presence_of_computer_model
    if computer_model.nil?
      computer_model = ComputerModel.default
    end
  end
  
  # Return the latest instance of ClientLog
  def last_report
    managed_install_reports.last
  end
  
  # Returns, in words, the time since last run
  def time_since_last_report
    if last_report.present?
      time_ago_in_words(last_report.created_at) + " ago"
    else
      "never"
    end
  end
  
  def time_since_last_error_free_report
    if last_error_free_report.present?
      time_ago_in_words(last_error_free_report.created_at) + " ago"
    else
      "never"
    end
  end
  
  def last_error_free_report
    managed_install_reports.error_free.last if managed_install_reports.error_free.present?
  end
  
  def recent_reports(num = 15)
    ManagedInstallReport.where(:computer_id => id).limit(num).order("created_at desc")
  end
  
  # Check the last managed install report and determine if 
  # this item has been installed or not
  def installed?(pkg)
    package_installed = false
    report = last_report
    if report.present? and report.managed_installs.present?
      report.managed_installs.each do |mi|
        if mi["name"] == pkg.name and mi["installed_version"] == pkg.version and mi["installed"]
          package_installed = true
        end
      end
    end
    package_installed
  end
  
  # True if an AdminMailer computer report is due
  def report_due?
    last_report.present? and last_report.issues?
  end
  
  # Get the status of the computer based on the last report
  # => Status Unknown
  # => OK
  # => Reported Errors
  # => Reported Warnings
  def status
    status = "Status Unknown"
    if last_report.present?
      status = "OK" if last_report.ok?
      status = "Reported Warnings" if last_report.warnings?
      status = "Reported Errors" if last_report.errors?
    end
    status
  end
  
  # Do some reformatting before writing to attribute
  def mac_address=(value)
    # Remove non-alphanumeric
    value = value.gsub(/[^a-zA-Z0-9]/,'')
    # Lower case
    value = value.downcase
    # Replace hyphens with colons
    i = 0
    formatted = []
    while(i < 12 and i < value.length) do
      formatted << value[i]
      formatted << ":" if i.odd? and i != 11
      i += 1
    end
    write_attribute(:mac_address,formatted.join(""))
  end
  
  # Bulk update
  def self.bulk_update_attributes(computers,computer_attributes)
    if computer_attributes.nil? or computers.empty? 
      raise ComputerError.new ("Nothing to update")
    else
      computers.each do |c|
        c.update_attributes(computer_attributes)
      end
    end
  end
  
  def self.bulk_update_attributes(packages,package_attributes)
    if package_attributes.nil? or packages.empty?
      raise PackageError.new ("Nothing to update")
    else
      results = packages.map do |p|
        p.update_attributes(package_attributes)
      end
      successes = results.map {|b| b == false }
      failures = results.map {|b| b == true }
      {:total => packages.count, :successes => successes.count, :failures => failures.count}
    end
  end
  
  def serial_number
    self.system_profile.serial_number if self.system_profile.present?
  end
  
  # updates warranty, return true upon success
  def update_warranty
    if serial_number
      warranty = Warranty.find_or_create_by_serial_number(serial_number)
      warranty_hash = {}
      begin
        warranty_hash = Warranty.get_warranty_hash(serial_number)
      rescue WarrantyException
        # Just catch and return false for now
        return false
      end
      # append computer_id into the hash
      warranty_hash[:computer_id] = self.id
      warranty_hash[:updated_at] = Time.now
      result = warranty.update_attributes(warranty_hash)
      if warranty_report_due? and result
        AdminMailer.warranty_report(self).deliver
        self.warranty.notifications.create
      end
      result ? true : false
    end
  end
  
  # Return true if warranty is about to expire in 30, 15, 5 days
  def warranty_report_due?
    if warranty.hw_coverage_end_date.present?
      # if no notification send before and is less than 30 days untill expires
      if warranty.notifications.nil? and (Time.now.to_date >= send_notifications_on.first)
        return true
      elsif notifications_not_sent.include?(true) 
        return true
      else
        return false
      end
    else
      # no hardware coverage found
      return false
    end
  end
  
  # Return an array of booleans true if notifications not sent
  def notifications_not_sent
    results = []
    send_dates = send_notifications_on
    send_dates.each do |date|
      results << (Time.now.to_date > date)
    end
    results
  end
  
  # Return how many days until the warrany expires
  def warranty_days_left
    if warranty.hw_coverage_end_date.present?
      diff = warranty.hw_coverage_end_date.to_date - Time.now.to_date
      diff.to_i
    end
  end
  
  # Return the days since last notification send
  def days_since_last_warranty_report
    last_send_date = warranty.notifications.last.updated_at.to_date
    days_apart = Time.now.to_date - last_send_date
    days_apart.to_i
  end
  
  # Return an array of real dates the notifications suppose to be send
  def send_notifications_on
    interval = [90,30,15,5]
    notification_send_on = []
    interval.each do |date|
      notification_send_on << warranty.hw_coverage_end_date.to_date - date
    end
    notification_send_on
  end
end