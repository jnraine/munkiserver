class Package < ActiveRecord::Base
  magic_mixin :unit_member
  
  # Dependancy relationships
  belongs_to :package_branch, :autosave => true
  belongs_to :package_category
  belongs_to :icon
  has_many :require_items, :as => :manifest
  has_many :update_for_items, :as => :manifest
  
  serialize :installs, Array
  serialize :receipts, Array
  serialize :supported_architectures, Array
  serialize :raw_tags
  
  scope :recent, lambda {|u| where("created_at > ?", 7.days.ago).where(:unit_id => u.id) }
  
  before_save :save_package_branch
  
  FORM_OPTIONS = {:restart_actions => [['None','None'],['Logout','RequiredLogout'],['Restart','RequiredRestart'],['Shutdown','Shutdown']],
                  :os_versions => [['Any',''],['10.4','10.4.0'],['10.5','10.5.0'],['10.6','10.6.0']],
                  :installer_types => [['Package',''],['App DMG','appdmg'],['AdobeUberInstaller'],['AdobeAcrobatUpdater']]}
  
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
  
  # Virtual attribute getter
  # Converts the receipts array into a plist
  def receipts_plist
    begin
      receipts.to_plist
    rescue NoMethodError
    end
  end
  
  # Virtual attribute setter
  # Takes a plist string and converts it to a ruby object and assigns it to receipts
  def receipts_plist=(value)
    obj = value.from_plist
    self.receipts = obj
  end
  
  # Virtual attribute getter
  # Converts the installs array into a plist
  def installs_plist
    begin
      installs.to_plist
    rescue NoMethodError
    end
  end
  
  # Virtual attribute setter
  # Takes a plist string and converts it to a ruby object and assigns it to receipts
  def installs_plist=(value)
    obj = value.from_plist
    self.installs = obj
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
      i = package_category.icon
    end
    i
  end
  
  # Setter for new_icon virtual attribute
  # Creates a new icon object and assigns to self.icon
  def new_icon=(value)
    unless value.blank?
      i = Icon.new({:uploaded_data => value})
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
  def destroy
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
  
  # Extend save
  # => Ensure we have at least a generic icon!
  def save
    if self.icon == nil
      self.icon = Icon.generic
    end
    super
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
    update_for_options = PackageBranch.unit_member(model_obj).map { |e| [e,e] unless e.id == model_obj.package_branch.id }.compact
    update_for_selected = model_obj.update_for_items.map(&:package_branches).map(&:to_s)
    requires_options = Package.where(:unit_id => model_obj.unit_id).where("id != #{model_obj.id}").map { |e| [e.to_s(:version),e.to_s(:version)] }
    requires_selected = model_obj.require_items.map(&:package).map {|e| e.to_s(:version) }
    
    model_name = self.to_s.underscore

    # Array for table_asm_select
    [{:title => "Update for",
      :model_name => model_name,
      :attribute_name => "update_for_tas",
      :select_title => "Select a package",
      :options => update_for_options,
      :selected_options => model_obj.update_for_ids,
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

  # Determines what catalog this belongs to
  def catalogs
    ["#{unit.id}_#{environment}.plist"]
  end
  
  # Setter for the raw_tags attribute
  # Converts the plist string value to
  # a ruby object and assigns it to the 
  # attribute
  # Takes a raw plist string
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
    if raw_mode == "Exclusive"
      h = raw_tags unless raw_tags.blank?
    else
      # Take care of the straight forward mappings
      [:name,:display_name,:receipts,:description,:minimum_os_version,:maximum_os_version,
       :installs,:RestartAction,:package_path,:autoremove,:installer_type,:installed_size,:installer_item_size,
       :installer_item_location,:uninstall_method,:uninstaller_item_location,:uninstaller_item_size,:uninstallable,
       :requires,:update_for,:catalogs,:supported_architectures,:version].each do |key|
        h[key.to_s] = self.send(key) unless self.send(key).blank?
      end
      if raw_mode == "Append"
        h = h.merge(raw_tags) unless raw_tags.blank?
      end
    end
    h
  end

  def raw_mode
    Package.raw_mode(raw_mode_id)
  end

  # Store raw_mode ID map
  def self.raw_mode(int)
    case int
      when 0 then "None"
      when 1 then "Append"
      when 2 then "Exclusive"
    end
  end

  # Converts serialized object into plist string
  def to_plist
    serialize_for_plist.to_plist
  end
  
  # True if this package supportes intel computers
  def intel?
    supported_architectures.include?("i386")
  end
  
  # True if this package supportes PPC computers
  def ppc?
    supported_architectures.include?("ppc")
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
  def self.upload(file, options = {})
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
    # Check package in
    begin
      Package.checkin(dest_path, options)
    rescue PackageError
      FileUtils.remove(dest_path)
      raise PackageError("There was a problem checking in #{dest_path}. It has been deleted.")
    end
  end
  
  # Renames item at path with escaped installer item name
  # Pass an absolute path for best results
  def self.rename_installer_item(path)
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
        # package.description = existing_version.description
        #         package.icon = existing_version.icon
        #         package.package_category_id = existing_version.package_category_id
        #         package.installs = existing_version.installs
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
    {:supported_architectures => ['i386','ppc']}
  end
  
  # Creates Pkgsinfo model object from valid plist
  # Typically, this method is passed the output file created from makepkgsinfo (upon upload or check-in)
  def self.import(plist_file)
    p = Package.new
    h = File.read(plist_file).from_plist
    if h.nil?
      raise PackageError("There was a problem parsing the plist provided from makepkginfo")
    else
      # Remove items that we don't need
      h.delete('catalogs')
      # Apply default values
      p.attributes = Package.default_attributes
      # Find or create a package branch for this
      p.name = h['name']
      h.delete('name')
      # This will barf if a key exists in h that isn't an attribute of this model
      p.attributes = h
      # Assign a package category
      p.package_category_id = PackageCategory.default(p.installer_type).id
      p
    end
  end
end