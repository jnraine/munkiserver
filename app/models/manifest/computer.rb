class Computer < ActiveRecord::Base
  magic_mixin :manifest
  magic_mixin :client_pref
  
  belongs_to :computer_model
  belongs_to :computer_group
  
  has_one :system_profile
  
  has_many :client_logs
  has_many :managed_install_reports
  
  # Validations
  validate :computer_model
  validates_presence_of :name
  # mac_address attribute must look something like ff:12:ff:34:ff:56
  validates_format_of :mac_address, :with => /^([0-9a-f]{2}(:|$)){6}$/
  validates_format_of :name, :with => /^[a-zA-Z0-9-]+$/, :message => "must only contain alphanumeric and hyphens characters"
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
  
  # Overwrite computer_model association method to return 
  # computer model based on system_profile
  def computer_model
    model = ComputerModel.where(:name => system_profile.machine_model).first if system_profile.present?
    model ||= ComputerModel.find(computer_model_id) if computer_model_id.present?
    model ||= ComputerModel.default
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
    # (self.last_successful_run.nil? and self.created_at < self.class.dormant_interval) or (self.last_successful_run.created_at < self.class.dormant_interval)
    false
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
  # bulk update 
  def self.bulk_update_attributes(computers,p)
    computers.each do |c|
      c.update_attributes(p.reject {|k,v| v.blank?})
    end
  end
  
  # overwirte to_param so the name of the commputer can be displayed in the URL
  def to_param
    name
  end
  
end