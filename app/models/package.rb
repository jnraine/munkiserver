require 'digest'
require 'os_range_helper'

class Package < ActiveRecord::Base
  include HasAUnit
  include HasAnEnvironment
  include HasAnIcon
  
  # Dependancy relationships
  belongs_to :package_branch
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
  
  has_one :version_tracker, :through => :package_branch, :autosave => true
  
  serialize :installs
  serialize :receipts
  serialize :supported_architectures, Array
  serialize :raw_tags
  serialize :installer_choices_xml
  
  after_initialize :init
  
  scope :recent, lambda {|u| where("created_at > ?", 7.days.ago).where(:unit_id => u).order("created_at DESC") }
  scope :shared, where(:shared => true)
  scope :from_other_unit, lambda {|p| where("unit_id != ?", p.unit_id)}
  scope :has_greater_version, lambda {|p| where("version > ?", p.version)}
  scope :other, lambda{|p| where("id <> ?", p.id)}
  
  before_save :handle_environment_change
  after_destroy :destroy_package_branch
  
  validates :version, :presence => true
  validates :installer_item_location, :presence => true
  validates :package_branch_id, :presence => true
  validates :receipts_plist, :plist => true
  validates :installs_plist, :plist => true
  validates :raw_tags_plist, :plist => true
  validates :receipts, :array => true
  validates :installs, :array => true
  validates :raw_tags, :hash => true
  validates_uniqueness_of :version, :scope => [:unit_id, :package_branch_id]
  validates :force_install_after_date_string, :date_time => true, :allow_blank => true
  
  FORM_OPTIONS = {:restart_actions         => [['None','None'],['Logout','RequiredLogout'],['Restart','RequiredRestart'],['Shutdown','Shutdown']],
                  :os_versions             => [[['Any','']], os_range(10,8,0..2), os_range(10,7,0..5), os_range(10,6,0..8), os_range(10,5,0..11)].flatten(1),
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
    unit = Unit.where(:shortname => params["unit_shortname"]).select("id").first
    package_branch = PackageBranch.where(:name => params["package_branch"], :unit_id => unit.id).select("id").first if unit.present?

    if package_branch.present?
      relation = where(:package_branch_id => package_branch.id).order("version DESC").limit(1)
      relation = relation.where(:version => params["version"]) if params["version"].present?
      relation.first
    end
  end

  # Initialize serialized data
  def init
    self.receipts ||= []
    self.installs ||= []
    self.raw_tags ||= {}
  end
  
  def destroy_package_branch
    package_branch.destroy if package_branch.packages.empty?
  end

  # An hash of params to be used for linking to a package instance
  # takes an optional params to specify the target unit
  def to_params
    params = {}
    params[:unit_shortname] = unit
    params[:package_branch] = package_branch
    params[:version] = version
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
    installer_item_locations = Package.where(:unit_id => unit.id).map(&:installer_item_location)
    # Set Null value if no item locations yet defined as MySQL must have a value for NOT IN()
    installer_item_locations = (installer_item_locations.map {|e| "'#{e}'"}.join(",")).nil? || "NULL"
    # Packages shared from other units
    packages = Package.shared.where("unit_id != ?", unit.id).where("installer_item_location NOT IN (?)", installer_item_locations)
    # Delete packages that refer to an installer item used by another package in unit
    # packages.delete_if {|p| installer_item_locations.include?(p.installer_item_location)}

  end
  
  # Recent items from other units that are shared
  def self.shared_recent(unit, time = 7.days.ago)
    shared_to_unit(unit).where("created_at > ?", time).order("created_at DESC")
  end
  
  # Returns array of packages shared to this unit that have been imported.  This is determined by
  # installer_item_location value
  def self.shared_to_unit_and_imported(unit)
    # Installer item locations from unit
    installer_item_locations = Package.where(:unit_id => unit.id).map(&:installer_item_location)
    # Packages shared from other units
    Package.shared.where("unit_id != ?",unit.id).where(:installer_item_location => installer_item_locations)
  end
  
  def name
    package_branch.name unless package_branch.nil?
  end
  
  def display_name
    package_branch.display_name unless package_branch.nil?
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
    obj = value.to_s.from_plist
    self.raw_tags = obj
  end
  
  def add_raw_tag(key,value)
    self.raw_mode_id = 1 if no_raw?
    h = self.raw_tags
    h[key] = value
    self.raw_tags = h
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
  
  def environments
    [environment]
  end
  
  # If package changed environment, remove all releations in install/uninstall/optional items
  # TO-DO: THIS IS SO UGLY
  def handle_environment_change
    if environment_id_changed? and not new_record?
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
  
  def package_category
    package_branch.package_category
  end
  
  # If there is no associated icon, then it asks for the package categories icon instead
  def icon
    icon = Icon.where(:id => icon_id).first
    icon ||= package_branch.icon
    icon ||= package_category.icon

    icon
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
    latest_in_unit.id == id unless latest_in_unit.nil?
  end
  
  # Return the latest package within this unit
  def latest_in_unit
    package_branch.latest
  end
  # Return true if the pacakge is the greatest within current unit and environment
  def latest_in_unit_and_environment?
    scoped = Package.where(:package_branch_id => self.package_branch_id, :unit_id => self.unit_id, :environment_id => self.environment_id)
    scoped = scoped.order("version DESC").limit(1)
    scoped.first.id == id
  end

  # Extend destroy method
  def destroy
    delete_package_file_if_necessary
    super
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
    update_for_options = PackageBranch.where("id <> ?", model_obj.package_branch.id).unit_and_environment(model_obj.unit, environment).map { |e| [e.to_s,e.to_s] }
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
              :requires,:update_for,:catalogs,:version, :force_install_after_date, :installer_choices_xml]
       
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
  
  def self.clone_packages(target_packages, unit)
    target_packages.map {|target_package| clone_package(target_package, unit) }
  end
  
  # Clone package to a given unit. Cloned package maintains cloneable attributes
  # and is assigned others based on the unit.
  def self.clone_package(target_package, unit)
    target_branch = target_package.package_branch

    Package.new do |p|
      target_package.cloneable_attributes.each do |name, value|
        p[name] = value
      end
      
      branch_attributes = {:name => target_branch.name,
                           :display_name => target_branch.display_name,
                           :unit_id => unit.id,
                           :package_category_id => target_branch.package_category_id}
      p.package_branch = ProcessPackageUpload::PackageAssembler.retrieve_package_branch(branch_attributes)
      
      p.unit = unit
      p.environment = Environment.start
    end
  end
  
  def self.clone_attributes
    ["version", "description", "icon_id", "filename", "minimum_os_version", "maximum_os_version", "RestartAction", "package_path", "autoremove", "version_tracker_version", "installer_type", "installed_size", "installer_item_size", "installer_item_location", "installer_choices_xml", "use_installer_choices", "uninstall_method", "uninstaller_item_location", "uninstaller_item_size", "uninstallable", "installer_item_checksum", "raw_mode_id", "preinstall_script", "postinstall_script", "uninstall_script", "preuninstall_script", "postuninstall_script", "unattended_install", "unattended_uninstall", "force_install_after_date", "receipts", "supported_architectures", "installs", "raw_tags"]
  end
  
  def cloneable_attributes
    cloneable_attributes = {}
    self.class.clone_attributes.each do |attribute_name|
      cloneable_attributes[attribute_name] = self[attribute_name]
    end
    
    cloneable_attributes
  end
  
  # over write the default get description, check if nil then get the description from version_trackers
  def description
    value = super
    if value.blank? and package_branch.present? and package_branch.version_tracker.present?
      package_branch.version_tracker.description
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
  
  def self.known_attributes
    @known_attributes ||= Package.new.attributes.keys
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
      raise PackageError.new("Nothing to update")
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
end
