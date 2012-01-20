class ManagedInstallReport < ActiveRecord::Base
  belongs_to :computer, :touch => :last_report_at

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
  
  # Returns the number of computers that checked in on a specific date
  def self.checkins(opts)
    default_opts = {:date => nil, :unit => nil, :start_date => nil, :end_date => nil}
    opts = default_opts.merge(opts)
    
    if opts[:date]
      checkins_on_date(opts)
    elsif opts[:start_date] and opts[:end_date]
      checkins_between(opts)
    end
  end
  
  def self.checkins_between(opts)
    default_opts = {:unit => nil, :start_date => nil, :end_date => nil}
    opts = default_opts.merge(opts)
    
    checkins_by_day = ActiveSupport::OrderedHash.new
    opts[:start_date].step(opts[:end_date],1) do |date|
      checkins_by_day[date.to_s] = cached_checkins_on_date(:date => date, :unit => opts[:unit])
    end
    checkins_by_day.values
  end
  
  # Returns an array of checkin values – one for each day
  #  DON'T CALL THIS -- IT IS BROKEN!
  # def self.checkins_between(opts)
  #   default_opts = {:unit => nil, :start_date => nil, :end_date => nil}
  #   opts = default_opts.merge(opts)
  # 
  #   scope = ManagedInstallReport.scoped
  #   scope = scope.where(:computer_id => opts[:unit].computers.map(&:id)) if opts[:unit].present?
  #   scope = scope.where('created_at >= ? and created_at <= ?', opts[:start_date].beginning_of_day, opts[:end_date].end_of_day)
  #   scope = scope.select("created_at, computer_id")
  #   scope = scope.joins("RIGHT JOIN (SELECT DISTINCT computer_id FROM managed_install_reports)")
  # 
  #   checkins_by_day = {}
  #   # Setup hash with days
  #   opts[:start_date].step(opts[:end_date],1) do |date|
  #     checkins_by_day[date.to_s] = 0
  #   end
  #   # Add each checkin to the proper day
  #   scope.each do |report|
  #     checkins_by_day[report.created_at.to_date.to_s] += 1
  #   end
  #   
  #   # Get the checkin numbers as an array
  #   checkins_by_day.values
  # end
  
  def self.cached_checkins_between(opts = {})
    default_opts = {:unit => nil, :start_date => nil, :end_date => nil}
    opts = default_opts.merge(opts)
    
    Rails.cache.fetch("checkins-for-unit-#{opts[:unit].id}-from-#{opts[:start_date]}-to-#{opts[:end_date]}", :expires_in => 15.minutes) do
      ManagedInstallReport.checkins_between(:start_date => opts[:start_date], :end_date => opts[:end_date], :unit => opts[:unit])
    end
  end
  
  # Fetch cached result for checkins.  Never cache today's
  # checkins.
  def self.cached_checkins_on_date(opts)
    default_opts = {:date => nil, :unit => nil}
    opts = default_opts.merge(opts)

    if opts[:date] ==  Date.today
      checkins_on_date(opts)
    else
      Rails.cache.fetch("checkins-for-unit-id-#{opts[:unit].id}-from-#{opts[:date]}") do
        checkins_on_date(opts)
      end
    end
  end

  def self.checkins_on_date(opts)
    default_opts = {:date => nil, :unit => nil}
    opts = default_opts.merge(opts)

    scope = ManagedInstallReport.scoped
    scope = scope.where(:computer_id => opts[:unit].computers.map(&:id)) if opts[:unit].present?
    scope = scope.where(:created_at => (opts[:date].beginning_of_day..opts[:date].end_of_day))
    scope = scope.count(:computer_id, :distinct => true)
  end
  
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
    report_hash.delete_if do |k,v|
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
end

