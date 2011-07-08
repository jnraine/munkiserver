# Special ActiveRecord::Base mixin module
module Manifest
  # Used to augment the class definition
  # of the class passed as an argument
  # Put class customization in here!
  def self.extend_class(k)
    k.class_exec do
      # ====================
      # = Code start here! =
      # ====================
      
      # Validations
      validate :uniqueness_of_name_in_unit
      validates_presence_of :name
      
      # Bundles
      has_many :bundle_items, :as => :manifest
      has_many :bundles, :through => :bundle_items
      
      # Install and uninstall items
      has_many :install_items, :as => :manifest
      has_many :uninstall_items, :as => :manifest
      
      # A list of user allowed install/uninstall items
      has_many :user_allowed_items, :as => :manifest
      
      # User specified install and uninstall items
      has_many :user_install_items, :as => :manifest
      has_many :user_uninstall_items, :as => :manifest
      
      # Optional Install items
      has_many :optional_install_items, :as => :manifest
              
      attr_is_hash :version_rollback
      
      magic_mixin :unit_member
      
      # True if name attribute is unique in the unit
      def uniqueness_of_name_in_unit
        # Create flag
        is_unique = true
        # Fetch all records from the same unit as self
        records = self.class.unit(self.unit)
        # Check each record and see if any one has the same name as self (except for self)
        records.each do |r|
          is_unique = false if r.name == self.name and r.id != self.id
        end
        # Return answer
        errors.add_to_base("Name (#{self.name}) has already been taken in this unit (#{self.unit})") unless is_unique
      end
      
      # Return all the environments visible to this object
      def environments
        environment.environments
      end
      
      # Returns an array of strings representing managed_installs
      # based on the items specified in install_items
      def managed_installs
        mi = []
        install_items.each do |install_item|
          if install_item.package_id.blank?
            mi << install_item.package.to_s
          else
            mi << install_item.package.to_s(:version)
          end
        end
        # unless self.additional_managed_installs.nil?
        #           mi.concat(additional_managed_installs)
        #         end
        mi
      end

      # Concatentates installs (specified by admins) and user installs (specified
      # by users) to create the managed_installs virtual attribute
      def managed_uninstalls
        mui = []
        uninstall_items.each do |uninstall_item|
          if uninstall_item.package_id.blank?
            mui << uninstall_item.package.to_s
          else
            mui << uninstall_item.package.to_s(:version)
          end
        end
        mui
      end
      
      # Same as managed_installs and managed_uninstalls
      # optional_installs virtual attribute let user to choose a list of items to install
      def optional_installs
        oi = []
        optional_install_items.each do |optional_install_item|
          if optional_install_item.package_id.blank?
            oi << optional_install_item.package.to_s
          else
            oi << optional_install_item.package.to_s(:version)
          end
        end
        oi
      end      
      
      # Pass a package object or package ID to append the package to this record
      # If the package's package branch, or another version of the package is specified
      # this package replaces the old
      def append_package_install(package)
        begin
          # Try to find the package, unless we have a package instance
          package = Package.find(package) unless package.class == Package
        rescue
          raise ComputerException.new("Malformed argument passed to append_package_install method")
        end
        its = self.install_items
        # Remove install items referring to the same package branch as "package"
        its = its.map do |it|
          it unless it.package_branch.id == package.package_branch.id
        end
        its = its.compact
        its << self.install_items.build({:package_id => package.id, :package_branch_id => package.package_branch.id})
        self.install_items = its
      end

      # Add package objects or IDs using append_package_installs
      # TO-DO Could be improved by rewrite, as it simply calls another,
      # more expensive method
      def append_package_installs(packages)
        packages.map {|package| self.append_package_branch_install(package) }
      end
      
      # Pass a package branch object or package branch ID to append the 
      # package branch to this record.  If the package's package branch, 
      # or another version of the package is specified this package 
      # replaces the old
      def append_package_branch_install(pb)
        begin
          # Try to find the package, unless we have a package instance
          pb = PackageBranch.find(pb) unless pb.class == PackageBranch
        rescue
          raise ComputerException.new("Malformed argument passed to append_package_branch_install method")
        end
        its = self.install_items
        # Remove install items referring to the same package branch as "pb"
        its = its.map do |it|
          it unless it.package_branch.id == pb.id
        end
        its = its.compact
        its << self.install_items.build({:package_branch_id => pb.id})
        self.install_items = its
      end
      
      # Add package branch items using append_package_branch_installs
      # TO-DO Could be improved by rewrite, as it simply calls another,
      # more expensive method
      def append_package_branch_installs(pbs)
        pbs.map {|pb| self.append_package_branch_install(pb) }
      end
      
      # Pass a list of Package records or package IDs and install_item associations will be built
      def package_installs=(packages)
        package_objects = [];
        packages.each do |package|
          if package.class == Package
            package_objects << package
          else
            p = Package.where(:id => package.to_i).limit(1).first
            package_objects << p unless p.nil?
          end
        end
        self.installs = package_objects
      end
      
      # Pass a list of Package records or package IDs and install_item associations will be built
      def package_branch_installs=(package_branches)
        pb_objects = [];
        pbs.each do |package_branch|
          if package_branch.class == PackageBranch
            pb_objects << package_branch
          else
            pb = PackageBranch.where(:id => package_branch.to_i).limit(1).first
            pbs_objects << p unless p.nil?
          end
        end
        self.installs = pb_objects
      end
      
      # Assign the list of items to a specific association (assoc)
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
      
      # Gets the packages that belong to this manifests installs virtual attribute
      def installs
        install_items.collect(&:package)
      end
      
      # Pass a list of Package or PackageBranch records and install_item associations will be built
      def installs=(list)
        build_package_association_assignment(:install_items,list)
      end
      
      def installs_package_branch_ids
        install_items.collect(&:package_branch).uniq.collect(&:id)
      end
      
      # Gets the packages that belong to this manifests uninstalls virtual attribute
      def uninstalls
        uninstall_items.collect(&:package)
      end

      def uninstalls=(list)
        build_package_association_assignment(:uninstall_items,list)
      end

      def uninstalls_package_branch_ids
        uninstall_items.collect(&:package_branch).uniq.collect(&:id)
      end

      # Gets the packages that belong to this manifests user_installs virtual attribute      
      def user_installs
        user_install_items.collect(&:package)
      end
      
      # Pass a list of Package or PackageBranch records and install_item associations will be built
      def user_installs=(list)
        build_package_association_assignment(:user_install_items,list)
      end
      
      def user_installs_package_branch_ids
        user_install_items.collect(&:package_branch).uniq.collect(&:id)
      end
      
      # Gets the packages that belong to this manifests user_uninstalls virtual attribute      
      def user_uninstalls
        user_uninstall_items.collect(&:package)
      end
      
      # Pass a list of Package or PackageBranch records and install_item associations will be built
      def user_uninstalls=(list)
        build_package_association_assignment(:user_uninstall_items,list)
      end  

      def user_uninstalls_package_branch_ids
        user_uninstall_items.collect(&:package_branch).uniq.collect(&:id)
      end
      
      
     # Gets the packages that belong to this manifests optional_installs virtual attribute
      def optional_installs
        optional_install_items.collect(&:package)
      end

      # Pass a list of Package or PackageBranch records and optional_install_items associations will be built
      def optional_installs=(list)
        build_package_association_assignment(:optional_install_items,list)
      end

      def optional_installs_package_branch_ids
        optional_install_items.collect(&:package_branch).uniq.collect(&:id)
      end      
      
      # Returns all package_branches that belongs to the unit and the environment
      def assignable_package_branches
        # Grab all package branches referenced by packages of this unit and environment
        # TO-DO use include to minimize db queries made for package_branches
        packages = Package.unit(unit).environments(environments)
        package_branches = packages.collect { |p| p.package_branch }
        
        # Remove duplicate package branches from the list of package branches
        uniq_pb_ids = []
        uniq_pbs = []
        package_branches.each do |pb|
          unless uniq_pb_ids.include?(pb.id)
            uniq_pbs << pb
            uniq_pb_ids << pb.id
          end
        end
        
        uniq_pbs
      end
      
      # add the path to the plist, called by included_manifests
      def to_s(format = nil)
        case format
          when :unique then "#{id}_#{name}"
          when :path then "#{Unit.where(:id => self.unit_id).first.name}/#{self.class.to_s.pluralize.tableize}/#{self.to_s(:unique)}"
          else name
        end
      end

      # Create a hash intended for plist output
      # Won't include the entire object attributes
      # but only the ones relevant for munki clients
      def serialize_for_plist
        h = {}
        h[:name] = name
        h[:included_manifests] = included_manifests
        h[:managed_installs] = managed_installs
        h[:managed_uninstalls] = managed_uninstalls
        h[:optional_installs] = optional_installs
        h
      end
      
      alias :serialize_for_plist_super :serialize_for_plist
      
      # Converts serialized object into plist string
      def to_plist
        serialize_for_plist.to_plist
      end
      
      def included_manifests
        a = bundles.collect {|e| "#{e.to_s(:path)}.plist"}
        if self.respond_to?(:computer_group)
          a << "#{computer_group.to_s(:path)}.plist" unless computer_group.nil?
        end
        a
      end
      
      
      # assuming computer calles to check and return a hash of available download items 
      # from Bundle and Computer Group
      def additional_managed_installs
        additional_installs = []
        if self.bundles.present?
          # if there is only one instance of Bundle
          if self.bundles.class == Bundle
            additional_installs.concat(bundle.managed_installs)
          else
            self.bundles.each do |bundle|
              additional_installs.concat(bundle.managed_installs)
            end
          end
        end
        if self.computer_group.present?
          # if there is only one instance of ComputerGroup
          if self.computer_group.class == ComputerGroup
            additional_installs.concat(self.computer_group.managed_installs)
          else
            self.computer_group.each do |cg|
              additional_installs.concat(self.computer_group.managed_installs)
            end
          end
        end
        additional_installs
      end
      
      # Attempts a couple different queries in order of importance to
      # find the appropriate record for the show action
      def self.find_for_show(s)
        # Find by ID, if s is only digits
        record = self.where(:id => s).first if s.match(/^\d+$/)
        # Find by id-name
        match = s.match(/^(\d+)([-_]{1})(.+)$/)
        if record.nil? and match.class == MatchData
          id = match[1]
          name = match[3]
          record ||= self.where(:id => id, :name => name).first
        end
        # Find by name
        record ||= self.where(:name => s).first
        # Return results
        record
      end
      # Alias to allow quasi super access
      class << self
        alias :find_for_show_super :find_for_show
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
        pkg_branch_options = PackageBranch.unit_member(model_obj).collect { |e| [e.name,e.id] }
        if model_obj.class == Bundle
          bundle_options = Bundle.where('id <> ?',model_obj.id).unit_member(model_obj).collect { |e| [e.name,e.id] }
        else
          bundle_options = Bundle.unit_member(model_obj).collect { |e| [e.name,e.id] }
        end
        
        model_name = self.to_s.underscore

        # Array for table_asm_select
        [{:title => "Bundles",
          :model_name => model_name,
          :attribute_name => "bundles",
          :select_title => "Select a bundle",
          :options => bundle_options,
          :selected_options => model_obj.bundle_ids },
         {:title => "Installs",
          :model_name => model_name,
          :attribute_name => "installs",
          :select_title => "Select a package branch",
          :options => pkg_branch_options,
          :selected_options => model_obj.installs_package_branch_ids },
         {:title => "Uninstalls",
          :model_name => model_name ,
          :attribute_name => "uninstalls",
          :select_title => "Select a package branch",
          :options => pkg_branch_options,
          :selected_options => model_obj.uninstalls_package_branch_ids },
          {:title => "Optional Install",
          :model_name => model_name,
          :attribute_name => "optional_installs",
          :select_title => "Select Optional Intalls",
          :options => pkg_branch_options,
          :selected_options => model_obj.optional_installs_package_branch_ids }]
      end
      
      # Return the default record
      # Requires a unit to be passed
      def self.default(unit)
        r = self.unit(unit).find_by_name("Default")
        r ||= self.unit(unit).find_by_name("default")
        r ||= self.unit(unit).first
      end
      
      
      # overwrite default to_param for friendly bundle URLs
      def to_param
        name
      end
      # ===================
      # = Code ends here! =
      # ===================
    end
  end
end