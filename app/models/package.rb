require 'digest'
require 'os_range_helper'

class Package < ActiveRecord::Base
  magic_mixin :unit_member
  
  # Dependancy relationships
  belongs_to :package_branch, :autosave => true
  accepts_nested_attributes_for :package_branch
  belongs_to :package_category
  belongs_to :icon
  has_many :dependents, :class_name => "RequireItem", :dependent => :destroy
  has_many :require_items, :as => :manifest, :dependent => :destroy
  has_many :updates, :class_name => "UpdateForItem", :dependent => :destroy
  has_many :update_for_items, :as => :manifest, :dependent => :destroy
  has_many :install_items, :dependent => :destroy
  has_many :uninstall_items, :dependent => :destroy
  has_many :optional_install_items, :dependent => :destroy
  has_many :managed_update_items, :dependent => :destroy
  has_many :user_install_items, :dependent => :destroy
  has_many :user_uninstall_items, :dependent => :destroy
  has_many :user_allowed_items, :dependent => :destroy
  
  serialize :installs
  serialize :receipts
  serialize :supported_architectures, Array
  serialize :raw_tags
  
  scope :recent, lambda {|u| where("created_at > ?", 7.days.ago).where(:unit_id => u) }
  scope :shared, where(:shared => true)
  scope :from_other_unit, lambda {|p| where("unit_id != ?", p.unit_id)}
  scope :has_greater_version, lambda {|p| where("version > ?", p.version)}
  scope :other, lambda{|p| where("id <> ?", p.id)}
  
  before_save :save_package_branch
  before_save :handle_environment_change
  
  validates :version, :presence => true
  validates :installer_item_location, :presence => true
  validates :package_branch_id, :presence => true
  validates :receipts_plist, :plist => true
  validates :installs_plist, :plist => true
  validates :raw_tags_plist, :plist => true
  validates :receipts, :array => true
  validates :installs, :array => true
  validates :raw_tags, :hash => true
  validates :version, :uniqueness_in_unit => true  
  validates :force_install_after_date_string, :date_time => true, :allow_blank => true
  
  FORM_OPTIONS = {:restart_actions         => [['None','None'],['Logout','RequiredLogout'],['Restart','RequiredRestart'],['Shutdown','Shutdown']],
                  :os_versions             => [[['Any','']], os_range(10,7,0..2), os_range(10,6,0..8), os_range(10,5,0..11)].flatten(1),
                  :installer_types         => [['Package',''],
                                               ['Copy From DMG', 'copy_from_dmg'],
                                               ['App DMG','appdmg'],
                                               ['AdobeUberInstaller'],
                                               ['AdobeAcrobatUpdater'],
                                               ['AdobeCS5PatchInstaller'],
                                               ['AdobeCS5Installer'],
                                               ['AdobeCS5AAMEEPackage'],
                                               ['AdobeSetup']],
                  :supported_architectures => ['i386','x86_64','ppc','Power Macintosh'],
                  :uninstall_method        => [['Remove Copied Items','remove_copied_items'],
                                               ['Remove Packages','removepackages'], 
                                               ['Remove App', 'remove_app'], 
                                               ['Uninstall Script', 'uninstall_script'],
                                               ['Uninstaller Script Location', ''],
                                               ['Uninstall Item Location', 'uninstaller_item_location'],                                                
                                               ['AdobeUberUninstaller','AdobeUberUninstaller'],
                                               ['AdobeSetup','AdobeSetup'],
                                               ['AdobeCS5AAMEEPackage','AdobeCS5AAMEEPackage']]}
  
  def self.find_where_params(params)
    unit = Unit.where(:shortname => params[:unit_shortname]).first
    package_branch = PackageBranch.where(:name => params[:package_branch]).first

    if unit.present? and package_branch.present?
      relation = self.unit(unit)
      relation = relation.where(:package_branch_id => package_branch.id)
      relation = relation.order('version DESC')
      relation = relation.limit(1)
      relation = relation.where(:version => params[:version]) if params[:version].present?
      relation.first
    end
  end

  # An hash of params to be used for linking to a package instance
  # takes an optional params to specify the target unit
  def to_params
    params = {}
    params[:unit_shortname] = unit
    params[:package_branch] = package_branch
    params[:version] = version unless self.latest_in_unit?
    params
  end
  
  def force_install_after_date
    self[:force_install_after_date]
  end
  
  def force_install_after_date_string
    self.force_install_after_date.utc.strftime("%Y-%m-%d %I:%M %p") if self.force_install_after_date
  end
  
  def force_install_after_date_string=(time_str)
    self.force_install_after_date = ActiveSupport::TimeZone.new('UTC').parse(time_str)  
  end

  # Returns array of packages shared to this unit that have not been imported yet.  This is 
  # determined by comparing installer_item_location values.
  def self.shared_to_unit(unit)
    # Installer item locations from unit
    installer_item_locations = Package.where(:unit_id => unit).map(&:installer_item_location)
    # Packages shared from other units
    # TO-DO at the time of writing this there didn't seem to be a nice way to complete "NOT IN" sql statement so I hand coded it...possible sql injection security hole
    packages = Package.shared.where("unit_id != #{unit.id}").where("installer_item_location NOT IN (#{installer_item_locations.map {|e| "'#{e}'"}.join(",")})")
    # Delete packages that refer to an installer item used by another package in unit
    # packages.delete_if {|p| installer_item_locations.include?(p.installer_item_location)}

  end
  
  # Recent items from other units that are shared
  def self.shared_recent(unit, time = 7.days.ago)
    shared_to_unit(unit).where("created_at > ?", time)
  end
  
  # Returns array of packages shared to this unit that have been imported.  This is determined by
  # installer_item_location value
  def self.shared_to_unit_and_imported(unit)
    # Installer item locations from unit
    installer_item_locations = Package.where("unit_id == #{unit.id}").map(&:installer_item_location)
    # Packages shared from other units
    Package.shared.where("unit_id != #{unit.id}").where(:installer_item_location => installer_item_locations)
  end
  
  # Virtual attribute for accessing the associated package
  # branch name which this package belongs to
  def name
    package_branch.name unless package_branch.nil?
  end

  # Virtual setter for name attribute
  # Assigns an existing PackageBranch if one exists matching value, otherwise, a new one is created.
  def name=(value)
    if value != self.name
      # If the value is new, find or create the package branch and assign it
      # and delete the old one if no other package references it
      self.package_branch.destroy if Package.find_all_by_package_branch_id(self.package_branch_id).length == 1
      self.package_branch = PackageBranch.find_or_create_by_name(value)
    end
  end
  
  # Virtual attribute for accessing the associated package
  # branch display name which this package belongs to
  def display_name
    package_branch.display_name unless package_branch.nil?
  end
  
  # Virtual attribute setter
  def display_name=(value)
    package_branch.display_name = value
  end
  
  def plist_virtual_attribute_set(attribute, value)
    begin
       obj = value.from_plist
       self.send("#{attribute}=", obj)
     rescue RuntimeError
       # Cache string value
       instance_variable_set("@cached_#{attribute}_plist",value)
       self.send("#{attribute}=", nil)
     end
  end
  
  def plist_virtual_attribute_get(attribute)
    begin
      send(attribute).to_plist
    rescue NoMethodError
      # return the invalide attribute
      self.send("#{attribute}")
      # instance_variable_get("@cached_#{attribute}_plist")
    end
  end
  
  # Virtual attribute getter
  # Converts the receipts array into a plist
  def receipts_plist
    plist_virtual_attribute_get(:receipts)
  end
  
  # Virtual attribute setter
  # Takes a plist string and converts it to a ruby object and assigns it to receipts
  # If the plist string passed is not valid, nil is assigned instead
  def receipts_plist=(value)
    plist_virtual_attribute_set(:receipts,value)
  end
  
  # Virtual attribute getter
  # Converts the installs array into a plist
  def installs_plist
    plist_virtual_attribute_get(:installs)
  end
  
  # Virtual attribute setter
  # Takes a plist string and converts it to a ruby object and assigns it to receipts
  def installs_plist=(value)
    plist_virtual_attribute_set(:installs,value)
  end
  
  # Virutal attribute getter
  # Converts raw_tags hash into plist
  def raw_tags_plist
    plist_virtual_attribute_get(:raw_tags)
  end
  
  # Setter for the raw_tags attribute. Converts the plist string value to
  # a ruby object and assigns it to the attribute. Takes a raw plist string.
  def raw_tags_plist=(value)
    begin
      obj = value.from_plist
      yaml = obj.to_yaml
    rescue TypeError
      yaml = value.to_yaml
    rescue NoMethodError
      yaml = value.to_yaml
    end
    write_attribute(:raw_tags,yaml) unless yaml.nil?
    yaml
  end
  
  def add_raw_tag(key,value)
    self.raw_mode_id = 1 if no_raw?
    raw_tags_hash = self.raw_tags
    raw_tags_hash[key] = value
    write_attribute(:raw_tags,raw_tags_hash)
  end
  
  # Virtual attribute that parses the array value of a tabled asm select into package and 
  # package branches and assigns that value to the upgrade_for attribute
  def update_for_tas=(value)
    self.update_for = Package.parse_package_strings(value) if value != nil
  end

  # Virtual attribute that parses the array value of a tabled asm select into package and 
  # package branches and assigns that value to the requires attribute
  def requires_tas=(value)
    self.requires = Package.parse_package_strings(value) if value != nil
  end

  # Takes an array of strings and returns either a package or a package branch
  # depending on the format of the string.
  # => Package record returned if matching: "#{package_branch_name}-#{version}"
  # => PackageBranch record returned if matching: "#{package_branch_name}"
  def self.parse_package_strings(a)
    items = []
    a.each do |name|
      if split = name.match(/(.+)(-)(.+)/)
        # For packages
        pb = PackageBranch.where(:name => split[1]).limit(1).first
        p = Package.where(:package_branch_id => pb.id, :version => split[3]).first
        items << p unless p.nil?
      else
        # For package branches
        pb = PackageBranch.where(:name => name).limit(1).first
        items << pb unless pb.nil?
      end
    end
    items
  end

  # Attempts to save the package branch and returns the result
  def save_package_branch
    package_branch.save if package_branch.changed?
  end
  
  def environments
    [environment]
  end
  
  # If package changed environment, remove all releations in install/uninstall/optional items
  def handle_environment_change
    if environment_id_changed?
      # Handle references to this package
      self.optional_install_items.each(&:destroy)
      self.install_items.each(&:destroy)
      self.uninstall_items.each(&:destroy)
      self.managed_update_items.each(&:destroy)
      # Handle references to the package branch
      num_of_packages = self.package_branch.packages.where(:unit_id => self.unit_id, :environment_id => self.environment_id_was).count
      if num_of_packages == 1
        # There is only one version of this package in the environment 
        # and unit and we are about to move it.  Before doing so, destroy
        # all install items within that scope.
        computers = Computer.where(:unit_id => self.unit_id, :environment_id => self.environment_id_was)
        computer_groups = ComputerGroup.where(:unit_id => self.unit_id, :environment_id => self.environment_id_was)
        bundles = Bundle.where(:unit_id => self.unit_id, :environment_id => self.environment_id_was)
        manifests = computers + computer_groups + bundles
        manifest_ids = manifests.map {|m| m.id }
        # Destroy items belonging to manifests within the unit and old enviornmnet of the package
        OptionalInstallItem.where(:manifest_id => manifest_ids, :package_branch_id => self.package_branch_id).each(&:destroy)
        InstallItem.where(:manifest_id => manifest_ids, :package_branch_id => self.package_branch_id).each(&:destroy)
        UninstallItem.where(:manifest_id => manifest_ids, :package_branch_id => self.package_branch_id).each(&:destroy)
      end
    end
  end
  
  # Returns a URL path to the package download
  def public_filename
    "/packages/#{environment_id}/#{unit_id}/#{installer_item_location}"
  end
  
  # If there is no associated icon, then it asks for the package categories icon instead
  def icon
    begin
      i = Icon.find(icon_id)
    rescue ActiveRecord::RecordNotFound
      i = package_branch.version_tracker.icon
      i ||= package_category.icon if package_category.respond_to?(:icon)
    end
    i
  end
  
  # Setter for new_icon virtual attribute
  # Creates a new icon object and assigns to self.icon
  def new_icon=(value)
    # Create new icon unless value.blank?
    unless value.blank?
      i = Icon.new({:photo => value})
      # If icon is saved, assign it to the record
      self.icon = i if i.save
    end
  end
  
  # Return array of IDs of packages that share the same 
  # installer item location.  Optionally, can pass a unit
  # to scope the results to.
  def shared_installer_item_location(unit = nil, reload = false)
    unit_id = unit.present? ? unit.id : 0
    @shared_installer_item_location_packages ||= []
    if @shared_installer_item_location_packages[unit_id].blank? or reload
        package_scope = Package.other(self)
        package_scope = package_scope.where(:installer_item_location => self.installer_item_location)
        package_scope = package_scope.where(:unit_id => unit.id) if unit.present?
        @shared_installer_item_location_packages[unit_id] = package_scope.to_a
      end
      @shared_installer_item_location_packages[unit_id]
  end
  
  # Checks if the current package is the latest (newest version) 
  # package in the package branch in this unit.
  def latest_in_unit?
    latest_in_unit.id == id
  end
  
  #Return the latest package within this unit
  def latest_in_unit
    package_branch.packages.unit(self.unit).order("version DESC").first
  end
  # Return true if the pacakge is the greatest within current unit and environment
  def latest_in_unit_and_environment?
    scoped = Package.where(:package_branch_id => self.package_branch_id, :unit_id => self.unit_id, :environment_id => self.environment_id)
    scoped = scoped.order("version DESC").limit(1)
    scoped.first.id == id
  end

  # Extend destroy method
  # TO-DO Delete package from hard drive if no other package is referring to it
  def destroy
    delete_package_file_if_necessary
    destroy_pb_if_necessary
    super
  end
  
  # Destroy associated package_branch if the
  # package_branch only references the current package.
  def destroy_pb_if_necessary
    pb = package_branch
    p = pb.packages.first
    # If there is only one package in the package branch and it is
    # this one, destroy the package branch
    if pb.packages.length == 1 and pb.packages.first.id == self.id
      pb.destroy
    end
  end
  
  # Delete package on filesystem if no other package record is referring to it
  def delete_package_file_if_necessary
    # Unless, other packages reference the package on the filesystem
    unless Package.where(:installer_item_location => self.installer_item_location).length > 1
      begin
        FileUtils.remove(Munki::Application::PACKAGE_DIR + self.installer_item_location)
      rescue
        logger.error "Unable to remove #{self.installer_item_location} from filesystem"
      end
    end
  end
  
  # Assign the list of items to a specific association (assoc)
  # Copied from manifest magic mixin model.
  def build_package_association_assignment(assoc,list)
    # Blank out the association
    self.send("#{assoc}=",[])
    unless list.nil?
      list.each do |item|
        # Create association for...
        if item.class == Package
          # ...a specific package
          self.send("#{assoc}").build({:package_id => item.id, :package_branch_id => item.package_branch.id})
        elsif item.class == PackageBranch
          # ...the latest package from a package branch
          self.send("#{assoc}").build({:package_branch_id => item.id})
        end
      end
    end
  end
  
  # Virtual attributes that aggregates the require_items
  def requires
    require_items.collect(&:package)
  end
  
  def require_ids
    requires.map(&:id)
  end

  def requires=(list)
    build_package_association_assignment(:require_items,list)
  end
  
  # Virtual attributes that aggregates the update_for_items
  def update_for
    update_for_items.collect(&:package)
  end
  
  # Getter that aggregates the update_for_items package branch ids
  # TO-DO This is an unintuative design and will be confusing: update_for returns packages, update_for_ids returns package branch IDs
  def update_for_ids
    update_for_items.map(&:package_branch).map(&:id)
  end
  
  # Pass an array of packages and package branches
  def update_for=(list)
    build_package_association_assignment(:update_for_items,list)
  end

  # Getter for virtual attribute
  def version_tracker_web_id
    package_branch.version_tracker.web_id unless package_branch.version_tracker.nil?
  end
  
  # Setter for virtual attribute
  def version_tracker_web_id=(value)
    if package_branch.version_tracker.nil?
      raise PackageError.new("No version tracker record found")
    elsif value.blank?
      package_branch.version_tracker.web_id = nil
    elsif value.to_s.match('[0-9]+')[0].to_i.present?
      package_branch.version_tracker.web_id = value.to_s.match('[0-9]+')[0].to_i    
    end
  end
  
  # Require icon
  def require_icon
    if self.icon == nil
      self.icon = Icon.new
      self.icon.save
    end
  end
  
  # Get the latest package from a specific unit and environment
  def self.latest_from_unit_and_environment(u,e)
    pbs = PackageBranch.unit_and_environment(u,e)
    pbs.map(&:latest)
  end

  # Get the latest packages from a specific unit
  def self.latest_where_unit(unit)
    PackageBranch.unit(unit).map {|pb| pb.latest_where_unit(unit) }
  end
  
  # Default parameters for the table_asm_select method
  # Returns values for self
  def tas_params(environment_id = nil)
    self.class.tas_params(self,environment_id)
  end

  # Default parameters for a tabled_asm_select method
  # Takes an object of the current class and returns params
  def self.tas_params(model_obj, environment_id = nil)
    environment_id ||= model_obj.environment_id
    environment = Environment.find(environment_id)
    # Get all the package branches associated with this unit and environment
    update_for_options = PackageBranch.unit_and_environment(model_obj.unit,environment).map { |e| [e.to_s,e.to_s] unless e.id == model_obj.package_branch.id }.compact.sort{|a,b| a[0] <=> b[0]}
    update_for_selected = model_obj.update_for.map(&:package_branch).map(&:to_s)
    # update_for_selected = model_obj.update_for_items.map(&:package_branches).map(&:to_s)
    requires_options = Package.unit(model_obj.unit).environment(environment).where("id != #{model_obj.id}").map { |e| [e.to_s(:version),e.to_s(:version)] }.sort{|a,b| a[0] <=> b[0]}
    requires_selected = model_obj.require_items.map(&:package).map {|e| e.to_s(:version) }
    
    model_name = self.to_s.underscore

    # Array for table_asm_select
    [{:title => "Update for",
      :model_name => model_name,
      :attribute_name => "update_for_tas",
      :select_title => "Select a package",
      :options => update_for_options,
      :selected_options => update_for_selected,
      :helpful_string => "Select a package branch that this package updates"},
     {:title => "Requires",
      :model_name => model_name,
      :attribute_name => "requires_tas",
      :select_title => "Select a package",
      :options => requires_options,
      :selected_options => requires_selected,
      :helpful_string => "Select a specific package that this package needs installed"},]
  end
  
  # Return a blank receipt array
  def self.blank_receipt
    { 'name' => '',
      'filename' => '',
      'packageid' => '',
      'installed_size' => '',
      'version' => ''}
  end
  
  # Return a blank receipt array
  def self.blank_install
    { 'type' => '',
      'path' => '',
      'CFBundleName' => '',
      'CFBundleIdentifier' => '',
      'CFBundleShortVersionString' => '',
      'md5checksum' => ''}
  end
  
  # Returns true if installer type is a .pkg/.mpkg (in other words, blank)
  def installer_package?
    installer_type.blank?
  end
  
  # Returns true if installer type is appdmg
  def installer_appdmg?
    installer_type == "appdmg"
  end

  # Returns true if installer type is AdobeUberInstaller
  def installer_AdobeUberInstaller?
    installer_type == "AdobeUberInstaller"
  end
  
  # Overrides default to string method.  Specifies version if this package
  # isn't the latest of the current units
  def to_s(style = nil)    
    case style
    when :unique then
      if latest_in_unit?
        "#{id}_#{name}"
      else
        "#{id}_#{name}-#{version}"
      end
    when :version then "#{name}-#{version}"
    when :pretty then display_name
    when :pretty_with_version then "#{self.to_s(:pretty)} (#{version})"
    when :plist_path then "pkginfo/#{self.to_s(:unique)}.plist"
    when :download_filename then "#{name}-#{version}#{extension}"
    else name
    end
  end
  
  def versions
    package_branch.packages_like_unit_member(self)
  end
  
  # Get the version that corresponds with the version tracker version
  # This is intended to handle some oddities in the version tracker
  # database.  For example, if you version 3.0.1 and version tracker
  # has the same version but written as 3.0.1b, you may manually override
  # otherwise, it will return the version of this record.
  # This getter will grab the version attribute if version_tracker_version
  # is nil. Used by VersionTracker class.
  def vtv
    vtv = version_tracker_version
    vtv = version if vtv.blank?
    vtv
  end
  
  # Calls package_branch new version check method
  def new_version?
    package_branch.new_version?(self.unit)
  end
  
  # Create a hash intended for plist output
  # Won't include the entire object attributes
  # but only the ones relevant for munki clients
  def serialize_for_plist
    h = {}
    if exclusively_raw?
      h = raw_tags
    else
      # Take care of the straight forward mappings
      keys = [:name,:display_name,:receipts,:description,:minimum_os_version,:maximum_os_version,
              :installs,:RestartAction,:package_path,:autoremove,:installer_type,:installed_size,:installer_item_size,
              :installer_item_location,:uninstaller_item_location,:uninstaller_item_size,:uninstallable, :uninstall_method, :unattended_install, :unattended_uninstall,
              :preinstall_script, :postinstall_script, :uninstall_script, :preuninstall_script, :postuninstall_script,
              :requires,:update_for,:catalogs,:version, :force_install_after_date]
       
      keys.each do |key|
        h[key.to_s] = self.send(key) if self.send(key).present?
      end
      
      # Add append any special cases to the hash
      
      # Supported Architectures
      sa = self.supported_architectures.delete_if {|e| e == ""}
      h["supported_architectures"] = sa unless sa.empty?
      # Requires
      h["requires"] = self.requires.map {|p| p.to_s(:version) } unless self.requires.empty?
      h["installer_item_location"] = download_name
      
      # Add any raw tags
      h = h.merge(raw_tags) if append_raw?
      
      h.delete("RestartAction") if h["RestartAction"] == "None"
    end
    h
  end
  
  # Tells plist gem how to serialize this object
  # Turns the package into a string and then converts
  # that string into a plist node using the Plist gem
  def to_plist_node
    Plist::Emit.plist_node(self.to_s)
  end
  
  def no_raw?
    raw_mode_id == 0
  end
  
  def append_raw?
    raw_mode_id == 1
  end
  
  def exclusively_raw?
    raw_mode_id == 2
  end
  
  # Store raw_mode ID map
  # Used in the view or other places that benefit from human readable names
  def self.raw_mode(int)
    case int
      when 0 then "None"
      when 1 then "Append"
      when 2 then "Exclusive"
    end
  end
  
  def raw_mode
    self.raw_mode(raw_mode_id)
  end

  # Converts serialized object into plist string
  def to_plist
    plist = serialize_for_plist.to_plist
    # Fix ^M encoding CR issue
    plist.gsub(/\r\n?/, "\n")
  end
  
  # If the package branch's version tracker "looks_good", returns true
  def trackable?
    begin
      package_branch.version_tracker.looks_good?
    rescue NoMethodError
      false
    end
  end
  
  # Instantiate a package object from a package file and an optional
  # pkginfo file, as well as some options
  # package_file, pkginfo_file = nil, options = {}
  def self.create(options = {})
    defaults = {:special_attributes => {:environment_id => Environment.start.id}}
    options = defaults.deep_merge(options)
    validate_create_options(options)
    package_file = self.initialize_upload(options.delete(:package_file))
    package = process_package_file(package_file,options)
  end
  
  # Import package from other units to current_unit
  # new package will inherite most of the attributes from orginal
  # except for the list of the attributes below
  def self.import_package(unit, shared_package)
    package = Package.new(shared_package.attributes)
    # Do custom stuff to imported package
    package.unit = unit
    package.environment = Environment.start
    package.update_for = []
    package.requires = []
    package.icon = shared_package.icon
    package.shared = false
    package
  end
  
  # over write the default get description, check if nil then get the description from version_trackers
  def description
    value = super
    if value.blank? and self.package_branch.version_tracker.present?
      self.package_branch.version_tracker.description
    else
      value
    end
  end

  
  # A list of attributes that are inherited by new packages, if a previous version exists
  def self.inherited_attributes
    [:description, :icon, :package_category_id]
  end
  
  # Returns a hash of default attributes that are used to intialize
  # a new package object.
  def self.default_attributes
    {}
  end
  
  # Returns array of attributes that a package object knows how to deal with
  # Includes manually added virtual attributes, not stored directly to a db column
  def self.known_attributes
    # TO-DO find a better way to return a list of attribute keys
    @known_attributes = Package.new.attributes.keys + ["display_name"]
  end
  
  # True if update_for or requires have items
  def has_dependencies?
    update_for.length > 0 or requires.length > 0
  end

  def extension
    if installer_item_location.match(/(\.\w+)\z/)
      $1
    else
      ""
    end
  end
  
  def find_by_name (param)
    p = Package.new
    param = p.package_branch.name
  end
  
  def download_name
    "#{id}-#{to_s(:download_filename)}"
  end
  
  # Update multiple attributes
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
  
  
  def self.has_required_package?(package)
    RequireItem.where(:package_id => package.id).first.present?
  end
  
  def has_installer_item_size?
    installer_item_size != nil and installer_item_size > 0
  end

  private
    # Run makepkginfo on server against package file to generate a pkginfo
    def self.process_package_file(package_file,options = {})
      if Munki::Application::MUNKI_TOOLS_AVAILABLE and options[:pkginfo_file].nil?
        self.process_package_file_with_makepkginfo(package_file, options)
      elsif options[:pkginfo_file].present?
        self.process_pkginfo_file(options[:pkginfo_file],package_file,options)
      else
        raise PackageError.new("Package file and/or pkginfo file missing")
      end
    end

    # Generate command-line options string from hash
    def self.process_makepkginfo_cmd_line_options(cmd_line_options)
      cmd_line_options_array = cmd_line_options.map do |k,v| 
        v = v.gsub(/ /,'\ ')
        "--#{k}=#{v}" unless v.blank?
      end
      cmd_line_options_array.compact.join(" ")
    end

    # Process package_file with makepkginfo on localhost. Return a populated, 
    # unsaved instance of Package
    def self.process_package_file_with_makepkginfo(package_file,options)
      cmd_line_options = process_makepkginfo_cmd_line_options(options[:makepkginfo_options])

      # Run makepkginfo
      out_log = Tempfile.new("out_log")
      error_log = Tempfile.new("error_log")
      makepkginfo_succeeded = system("#{Munki::Application::MAKEPKGINFO} #{cmd_line_options} '#{package_file.path}' 1> '#{out_log.path}' 2>'#{error_log.path}'")
      exit_status = $?.exitstatus
  
      # If there was a problem, cleanup, then raise an error
      if exit_status != 0
        # Remove package and raise error
        FileUtils.rm(package_file.path)
        raise PackageError.new("Munki tools were unable to process package file: " + out_log.read + "\n" + error_log.read)
      end

      # pkginfo file, if all went well
      process_pkginfo_file(out_log,package_file,options)
    end
  
    # Process a pkginfo_file for package_file. Return a populated, unsaved 
    # instance of Package
    def self.process_pkginfo_file(pkginfo_file,package_file,options)
      pkginfo_hash = nil
    
      # Parse plist
      begin
        pkginfo_hash = Plist.parse_xml(pkginfo_file.read)
      rescue RuntimeError => e
        raise PackageError.new("Unable to parse pkginfo file -- Plist.parse_xml raised RuntimeError: #{e}")
      end
    
      # Make sure pkginfo_hash isn't nil
      if pkginfo_hash.nil?
        raise PackageError.new("Unable to parse pkginfo file -- Plist.parse_xml returned nil: pkginfo file probably empty")
      end
    
      # Create a package from hash
      self.process_pkginfo_hash(pkginfo_hash,package_file,options)
    end
  
    # Applies special attributes (unit, environment, other) to a package.
    def self.apply_special_attributes(package, attributes = {})
      attributes.each do |attribute,value|
        package.send("#{attribute}=",value)
      end
      package
    end
  
    # Apply inherited attributes (as defined by self.inherited_attributes)
    # from an older version from the package's package branch and unit
    def self.apply_previous_version_attributes(package)
      previous_version = Package.where(:package_branch_id => package.package_branch_id, :unit_id => package.unit_id).order('version DESC').first
      if previous_version.present?
        self.inherited_attributes.each do |attr|
          package.send("#{attr}=",previous_version.send(attr)) unless previous_version.send(attr).blank?
        end
      end
      package
    end
  
    # Instantiate a package from a hash. Deals with non-applicable values
    # generated by makepkginfo (such as the catalogs array) and other 
    # munki server special cases
    def self.process_pkginfo_hash(pkginfo_hash,package_file,options)
      package = Package.new
      # Remove items that we don't need
      pkginfo_hash.delete('catalogs')
      # Find or create a package branch for this
      pb_name = PackageBranch.conform_to_name_constraints(pkginfo_hash['name'])
      # Assgin a package branch to this new package
      package.package_branch = retrieve_package_branch(pb_name, pkginfo_hash)
      pkginfo_hash.delete('name')
      # Removes keys that are not attributes of a package and adds them to the raw_tags attribute
      pkginfo_hash.each do |k,v|
        unless known_attributes.include?(k)
          # Add non-attribute tag to raw_tags
          package.raw_tags = package.raw_tags.merge({k => v})
          # Remove non-attribute from hash
          pkginfo_hash.delete(k)
          # Change raw_mode to append
          package.raw_mode_id = 1
        end
      end
      # Assign attributes to package
      package.attributes = pkginfo_hash
      # Assign a package category based on the installer_type
      package.package_category_id = PackageCategory.default(package.installer_type).id
      # Ensure the installer_item_location is correct
      package.installer_item_location = File.basename(package_file.path)
      # Ensure the hash is correct
      package.add_raw_tag("installer_item_hash",Digest::SHA256.file(package_file.path).hexdigest)
      # Apply munkiserver attributes
      package = self.apply_special_attributes(package,options[:special_attributes])
      # Apply attributes from existing version in the same unit
      package = self.apply_previous_version_attributes(package)
      # debugger
      package
    end
    
    # Create a new package branch if not existing
    # else pick the existing package branch and assign to the package
    def self.retrieve_package_branch(pb_name, pkginfo_hash)
      pb = PackageBranch.find_or_create_by_name(pb_name)
      # Check if there exists package branch display name conflicts, if a new package branch record is created
      if pb.new_record?
        display_name = pkginfo_hash['display_name'].present? ? pkginfo_hash['display_name'] : pkginfo_hash['name']
        pb.display_name = PackageBranch.conform_to_display_name_constraints(display_name, pb.id)
        # Update and save the new package branch
        if pb.changed?
          unless pb.save
            raise PackageError.new("Error occurred while attempting to uniquify display name for package branch (#{package.package_branch})")
          end
        end
      end
      pb # need to call this the package branch, else return nothing
    end
    
    # Checks to ensure what should be present is. If something is missing, raise 
    # PackageError exception.
    def self.validate_create_options(options)
      raise PackageError.new("Please select a file") if options[:package_file].nil?
      raise PackageError.new("Must provide an :special_attributes option") if options[:special_attributes].nil?
      raise PackageError.new("Must provide a unit ID") if options[:special_attributes][:unit_id].nil?
      raise PackageError.new("Must provide an environment ID") if options[:special_attributes][:environment_id].nil?
    end

    # Renames and moves temporary files to the appropriate package store. Returns
    # a File object for newly renamed/moved file
    def self.initialize_upload(package_file)
      destination_path = nil
      
      # Get the absolute path for the package store
      begin
        unique_name = self.uniquify_name(package_file.original_filename)
        destination_path = Pathname.new(Munki::Application::PACKAGE_DIR + unique_name)
      end while File.exists?(destination_path)

      # Move tmp_file to the package store
      begin
        FileUtils.mv package_file.tempfile.path, destination_path
      rescue Errno::EACCES => e
        raise PackageError.new("Unable to write to package store")
      end

      # Return the package as a File object
      begin
        File.new(destination_path)
      rescue
        raise PackageError.new("Unable to read #{destination_path}")
      end
    end

    # Create a unique name from a string by prepending the current timestamp
    # and adding a random number
    def self.uniquify_name(name)
      Time.now.to_s(:ordered_numeric) + rand(10001).to_s + "_" + name
    end
end
