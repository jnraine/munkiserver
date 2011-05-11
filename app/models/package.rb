class Package < ActiveRecord::Base
  magic_mixin :unit_member
  
  # Dependancy relationships
  belongs_to :package_branch, :autosave => true
  accepts_nested_attributes_for :package_branch
  belongs_to :package_category
  belongs_to :icon
  has_many :require_items, :as => :manifest
  has_many :update_for_items, :as => :manifest
  
  serialize :installs, Array
  serialize :receipts, Array
  serialize :supported_architectures, Array
  serialize :raw_tags
  
  scope :recent, lambda {|u| where("created_at > ?", 7.days.ago).where(:unit_id => u.id) }
  scope :shared, where(:shared => true)
  
  before_save :save_package_branch
  before_save :require_icon
  
  validates :receipts, :plist_array => true
  validates :installs, :plist_array => true

  
  FORM_OPTIONS = {:restart_actions         => [['None','None'],['Logout','RequiredLogout'],['Restart','RequiredRestart'],['Shutdown','Shutdown']],
                  :os_versions             => [['Any',''],['10.4','10.4.0'],['10.5','10.5.0'],['10.6','10.6.0']],
                  :installer_types         => [['Package',''],
                                               ['Copy From DMG','copy_from_dmg'],
                                               ['App DMG','appdmg'],
                                               ['AdobeUberInstaller'],
                                               ['AdobeAcrobatUpdater'],
                                               ['AdobeCS5PatchInstaller'],
                                               ['AdobeCS5Installer'],
                                               ['AdobeCS5AAMEEPackage'],
                                               ['AdobeSetup']],
                  :supported_architectures => ['i386','x86_64','ppc','Power Macintosh']}
  
  # Returns array of packages shared to this unit that have not been imported yet.  This is 
  # determined by comparing installer_item_location values.
  def self.shared_to_unit(unit)
    # Installer item locations from unit
    installer_item_locations = Package.where("unit_id == #{unit.id}").map(&:installer_item_location)
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
      instance_variable_get("@cached_#{attribute}_plist")
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
  
  # Returns a URL path to the package download
  def public_filename
    "/packages/#{environment_id}/#{unit_id}/#{installer_item_location}"
  end
  
  # If there is no associated icon, then it asks for the package categories icon instead
  def icon
    begin
      i = Icon.find(icon_id)
    rescue ActiveRecord::RecordNotFound
      i = package_category.icon if package_category.respond_to?(:icon)
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
  
  # Checks if the current package
  # is the latest (newest) package
  # in the package branch
  def latest?
    package_branch.latest(self).id == id
  end

  # Extend destroy method
  # TO-DO Delete package from hard drive if no other package is referring to it
  def destroy
    delete_package_file_if_necessary_if_necessary
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
    package_branch.version_tracker_web_id
  end
  
  # Setter for virtual attribute
  def version_tracker_web_id=(value)
    package_branch.version_tracker_web_id = value
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
  
  # Default parameters for the table_asm_select method
  # Returns values for self
  def tas_params
    self.class.tas_params(self)
  end

  # Default parameters for a tabled_asm_select method
  # Takes an object of the current class and returns params
  def self.tas_params(model_obj)
    # Get all the package branches associated with this unit and environment
    update_for_options = PackageBranch.unit_member(model_obj).map { |e| [e.to_s,e.to_s] unless e.id == model_obj.package_branch.id }.compact
    update_for_selected = model_obj.update_for.map(&:package_branch).map(&:to_s)
    # update_for_selected = model_obj.update_for_items.map(&:package_branches).map(&:to_s)
    requires_options = Package.unit_member(model_obj).where("id != #{model_obj.id}").map { |e| [e.to_s(:version),e.to_s(:version)] }
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
      if latest?
        "#{id}_#{name}"
      else
        "#{id}_#{name}-#{version}"
      end
    when :version then "#{name}-#{version}"
    when :pretty then display_name
    when :pretty_with_version then "#{self.to_s(:pretty)} (#{version})"
    when :plist_path then "pkginfo/#{self.to_s(:unique)}.plist"
    else name
    end
  end
  
  def versions
    package_branch.packages_like_unit_member(self)
  end

  # Moved to UnitMember
  # Determines what catalog this belongs to
  # def catalogs
  #   ["#{unit.id}_#{environment}.plist"]
  # end
  
  # Setter for the raw_tags attribute. Converts the plist string value to
  # a ruby object and assigns it to the attribute. Takes a raw plist string.
  def raw_tags=(value)
    begin
      obj = Plist.parse_xml(value)
      yaml = obj.to_yaml
    rescue TypeError
      yaml = value.to_yaml
    end
    write_attribute(:raw_tags,yaml)
    yaml
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
              :installer_item_location,:uninstall_method,:uninstaller_item_location,:uninstaller_item_size,:uninstallable,
              :preinstall_script, :postinstall_script,
              :requires,:update_for,:catalogs,:version]
       
      keys.each do |key|
        h[key.to_s] = self.send(key) if self.send(key).present?
      end
      
      # Add append any special cases to the hash
      
      # Supported Architectures
      sa = self.supported_architectures.delete_if {|e| e == ""}
      h["supported_architectures"] = sa unless sa.empty?
      # Requires
      h["requires"] = self.requires.map {|p| p.to_s(:version) } unless self.requires.empty?
      
      # Add any raw tags
      h = h.merge(raw_tags) if append_raw?
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
    serialize_for_plist.to_plist
  end
  
  # If the package branch's version tracker "looks_good", returns true
  def trackable?
    begin
      package_branch.version_tracker.looks_good?
    rescue NoMethodError
      false
    end
  end
  
  # Takes a tmp file, moves it to the appropriate place, and checks it in
  # Return value is the same as Package.checkin.  If it fails, it will raise
  # an PackageError exception
  def self.upload(file, pkginfo, options = {})
    original_filename = nil
    if file.respond_to?(:original_filename)
      original_filename = file.original_filename
    else
      original_filename = File.basename(file.path)
    end
    
    # Add timestamp to original filename
    installer_item_name = Time.now.to_s(:ordered_numeric) + "_" + original_filename
    # Create absolute path
    dest_path = Munki::Application::PACKAGE_DIR + installer_item_name
    
    # Make sure a file of that name doesn't already exist and fix it if it does
    if File.exists?(dest_path)
      installer_item_name = Time.now.to_s(:ordered_numeric) + "_" + rand(1001) + "_" + original_filename
      dest_path = Munki::Application::PACKAGE_DIR + installer_item_name
    end
    
    # Move from the tmp location to destination
    FileUtils.move(file.path,dest_path)
    dest_path = Package.rename_installer_item(dest_path)
    
    # Checkin the package if the munki tools are available, or import if they are not
    if Munki::Application::MUNKI_TOOLS_AVAILABLE
      # Check package in
      begin
        Package.checkin(dest_path, options)
      rescue PackageError
        if FileUtils.remove(dest_path)
          raise PackageError.new("There was a problem checking in #{dest_path}")
        else
          raise PackageError.new("There was a problem checking in #{dest_path}. Unable to delete it.")
        end
      end
    else
      begin
        pkginfo_string = File.read(pkginfo)
        p = Package.import(pkginfo_string)
        p.installer_item_location = dest_path
        {:package => p, :plist_string => pkginfo_string}
      rescue Exception => e
        raise PackageError.new("There was an error while importing #{File.basename(dest_path)}")
      end
    end
  end
  
  # Renames item at path with escaped installer item name
  # Pass an absolute path for best results
  def self.rename_installer_item(path)
    # Convert path to Pathname object
    path = Pathname.new(path)
    # Split up path for manipulation
    dir = File.dirname(path)
    name = File.basename(path)
    # Escape it
    new_name = name.gsub(' ','_').gsub(/['"\(\)]/,'')
    new_path = Pathname.new("#{dir}/#{new_name}")

    # Move it if it is any different
    # Return new path if it works, old path if it doesn't work
    FileUtils.move(path,new_path) unless path == new_path
    if File.exists?(new_path)
      new_path
    else
      path
    end
  end
  
  # Creates a package instance from a temporary file, pkginfo file, and options.
  # Returns an unsaved instance of the Package class
  def self.create_from_uploaded_file(uploaded_file,pkginfo_file = nil, options = {})
    file = self.init_uploaded_file(uploaded_file)
    self.create(file,pkginfo_file,options)
  end
  
  # Renames and moves temporary files to the appropriate package store. Returns
  # a File object for newly renamed/moved file
  def self.init_uploaded_file(uploaded_file)
    destination_path = nil
    
    # Get the absolute path for the package store
    begin
      unique_name = self.uniquify_name(uploaded_file.original_filename)
      destination_path = Pathname.new(Munki::Application::PACKAGE_DIR + unique_name)
    end while File.exists?(destination_path)
    
    # Move tmp_file to the package store
    begin
      FileUtils.mv uploaded_file.tempfile.path, destination_path
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
  
  # Instantiate a package object from a package file and an optional
  # pkginfo file, as well as some options
  def self.create(package_file, pkginfo_file = nil, options = {})
    package = nil

    # Create a package
    if Munki::Application::MUNKI_TOOLS_AVAILABLE and pkginfo_file.nil?
      package = self.process_package(package_file, options[:makepkginfo_options])
    elsif pkginfo_file.present?
      package = self.process_pkginfo(pkginfo_file)
    else
      raise PackageError.new("Package file and/or pkginfo file missing")
    end
    
    # Apply munkiserver attributes
    package = self.apply_munki_server_attributes(package,options[:attributes][:unit_id],options[:attributes][:environment_id])
    
    # Apply attributes from existing version in the same unit
    package = self.apply_old_version_attributes(package)
  end
  
  # Run makepkginfo on server against package file to generate a pkginfo
  def self.process_package(file,makepkginfo_options = {})
    # Generate command-line options array
    cmd_line_options = makepkginfo_options.map do |k,v| 
      v = v.gsub(/ /,'\ ')
      "--#{k}=#{v}" unless v.blank?
    end
    cmd_line_options = cmd_line_options.compact
    
    # Run makepkginfo
    stdout_tmp_path = Pathname.new("/tmp/ms-#{File.basename(file)}-#{rand(100001)}.plist")
    stderr_tmp_path = Pathname.new("/tmp/ms-#{File.basename(file)}-#{rand(100001)}.plist")
    makepkginfo_succeeded = system("#{Munki::Application::MAKEPKGINFO} #{cmd_line_options.join(" ")} '#{file.path}' 1> '#{stdout_tmp_path}' 2>'#{stderr_tmp_path}'")
    exit_status = $?.exitstatus
    
    pkginfo = File.new(stdout_tmp_path)
    
    package = nil
    # Process pkginfo
    if exit_status == 0
      package = self.process_pkginfo(pkginfo)
    else
      # Remove package and raise error
      FileUtils.rm(file.path)
      raise PackageError.new("Munki tools were unable to process package file: " + File.read(stderr_tmp_path) + "\n" + File.read(stdout_tmp_path))
    end
    
    # Remove tmp files (no error checking)
    FileUtils.rm(stdout_tmp_path)
    FileUtils.rm(stderr_tmp_path)
    
    package
  end
  
  # Instantiate a package from a pkginfo file (File instance)
  def self.process_pkginfo(file)
    pkginfo_hash = nil
    
    # Parse plist
    begin
      pkginfo_hash = Plist.parse_xml(file.read)
    rescue RuntimeError => e
      raise PackageError.new("Unable to parse pkginfo file -- Plist.parse_xml raised RuntimeError: #{e}")
    end
    
    # Make sure pkginfo_hash isn't nil
    if pkginfo_hash.nil?
      raise PackageError.new("Unable to parse pkginfo file -- Plist.parse_xml returned nil: pkginfo file probably empty")
    end
    
    # Create a package from hash
    self.process_pkginfo_hash(pkginfo_hash)
  end
  
  # Applies munki server attributes (environment, unit) to a package.
  def self.apply_munki_server_attributes(package, unit_id, environment_id = nil)
    environment_id ||= Environment.start
    
    package.unit_id = unit_id
    package.environment_id = environment_id
    
    package
  end
  
  # Apply inherited attributes (as defined by self.inherited_attributes)
  # from an older version from the package's package branch and unit
  def self.apply_old_version_attributes(package)
    old_version = Package.where(:package_branch_id => package.package_branch_id, :unit_id => package.unit_id).order('version DESC').first
    if old_version.present?
      self.inherited_attributes.each do |attr|
        package.send("#{attr}=",old_version.send(attr)) unless old_version.send(attr).blank?
      end
    end
    package
  end
  
  # Instantiate a package from a hash. Deals with non-applicable values
  # generated by makepkginfo (such as the catalogs array) and other 
  # munki server special cases
  def self.process_pkginfo_hash(pkginfo_hash)
    package = Package.new
    
    # Remove items that we don't need
    pkginfo_hash.delete('catalogs')

    # Find or create a package branch for this
    pb_name = PackageBranch.conform_to_name_constraints(pkginfo_hash['name'])
    package.package_branch = PackageBranch.find_or_create_by_name(pb_name)
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
    
    package
  end
  
  # Creates valid and populated Pkgsinfo object
  # Pass path to package.  Returns a helpful hash
  # => :package - An new, unsaved package instance
  # => :plist_string - The string split out by MAKEPKGINFO
  def self.checkin(path, options = {})
    # Format options into command line options
    cmd_line_options = options.map do |k,v| 
      # Escape for spaces
      v = v.gsub(/ /,'\ ')
      "--#{k}=#{v}" unless v.blank?
    end
    cmd_line_options = cmd_line_options.compact
    # Rename package on disk to match proper style
    path = Package.rename_installer_item(path)
    logger.info "Checking in #{path}..."
    tmp_file_path = "/tmp/mor-#{rand(1000)}.plist"
    logger.info `#{Munki::Application::MAKEPKGINFO} #{cmd_line_options.join(" ")} "#{path}" > "#{tmp_file_path}"`
    exit_status = `echo $?`.chomp
    
    package = nil
    # If makepkgsinfo exited with zero and outputted a valid pkgsinfo plist file, continue.
    # TO-DO add a plist validator to this if
    if exit_status.to_i == 0
      package = Package.import(tmp_file_path)
      # Assign the starting environment
      package.environment = Environment.start
      
      # Set defaults based on previous records with the same name
      existing_version = Package.where(:package_branch_id => package.package_branch_id).order('version DESC').first
      unless existing_version.nil?
        # Call package.attr = existing_version.attr to assign inheritable attributes to the new package
        self.inherited_attributes.each do |attr|
          package.send("#{attr}=",existing_version.send(attr)) unless existing_version.send(attr).blank?
        end
      end

      # Determine installer_choices
      # TO-DO fix the installer_choices
      # pkgsinfo.installer_choices_xml = pkgsinfo.derive_installer_choices
    else
      logger.warn "Checking in #{File.basename(pkg_path)} failed!"
      logger.warn "Here's the output of makepkgsinfo:\n" + File.read(tmp_file_path)
    end
    
    # Build hash
    hash = {:package => package, :plist_string => File.read(tmp_file_path)}
    # Remove tmp file
    File.unlink(tmp_file_path)
    # Return hash
    hash
  end
  
  # A list of attributes that are inherited by new packages, if a previous version exists
  def self.inherited_attributes
    [:description, :icon, :package_category_id]
  end
  
  # Returns a hash of default attributes that are used to intialize
  # a new package object.  Used in self.import.
  def self.default_attributes
    {}
  end
  
  # Returns array of attributes that a package object knows how to deal with
  # Includes manually added virtual attributes, not stored directly to a db column
  def self.known_attributes
    # TO-DO find a better way to return a list of attribute keys
    @known_attributes = Package.new.attributes.keys + ["display_name"]
  end
  
  # Creates Pkgsinfo model object from valid plist
  # Typically, this method is passed the output file created from makepkgsinfo (upon upload or check-in)
  def self.import(plist_file)
    p = Package.new
    h = File.read(plist_file).from_plist
    if h.nil?
      raise PackageError.new("There was a problem parsing the plist provided from makepkginfo")
    else
      # Remove items that we don't need
      h.delete('catalogs')
      # Apply default values
      p.attributes = Package.default_attributes
      # Find or create a package branch for this
      p.name = h['name']
      h.delete('name')
      # Removes keys that are not attributes of a package and adds them to the raw_tags attribute
      h.each do |k,v|
        unless known_attributes.include?(k)
          # Add non-attribute tag to raw_tags
          p.raw_tags = p.raw_tags.merge({k => v})
          # Remove non-attribute from hash
          h.delete(k)
          # Change raw_mode to append
          p.raw_mode_id = 1
        end
      end
      
      # This will barf if a key exists in h that isn't an attribute of this model
      p.attributes = h
      # Assign a package category based on the installer_type
      p.package_category_id = PackageCategory.default(p.installer_type).id
      p
    end
  end
  
  # True if update_for or requires have items
  def has_dependencies?
    update_for.length > 0 or requires.length > 0
  end
end



# == Schema Information
#
# Table name: packages
#
#  id                        :integer         not null, primary key
#  version                   :string(255)
#  package_branch_id         :integer
#  unit_id                   :integer
#  environment_id            :integer
#  package_category_id       :integer
#  receipts                  :text            default("--- []")
#  description               :text
#  icon_id                   :integer
#  filename                  :string(255)
#  supported_architectures   :text            default("--- []")
#  minimum_os_version        :text
#  maximum_os_version        :text
#  installs                  :text            default("--- []")
#  RestartAction             :string(255)
#  package_path              :string(255)
#  autoremove                :boolean         default(FALSE)
#  shared                    :boolean         default(FALSE)
#  version_tracker_version   :string(255)
#  preinstall_script         :string(255)
#  postinstall_script        :string(255)
#  installer_type            :string(255)
#  installed_size            :integer
#  installer_item_size       :integer
#  installer_item_location   :string(255)
#  installer_choices_xml     :text
#  use_installer_choices     :boolean         default(FALSE)
#  uninstall_method          :string(255)
#  uninstaller_item_location :string(255)
#  uninstaller_item_size     :integer
#  uninstallable             :boolean         default(TRUE)
#  installer_item_checksum   :string(255)
#  raw_tags                  :text            default("--- {}")
#  raw_mode_id               :integer         default(0)
#  created_at                :datetime
#  updated_at                :datetime
#

