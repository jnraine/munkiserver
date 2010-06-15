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
      validates_uniqueness_of :name
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
      
      attr_is_hash :version_rollback
      
      magic_mixin :unit_member
      
      # Return all the environments visible to this object
      def environments
        environment.environments
      end
      
      # Concatentates installs (specified by admins) and user installs (specified
      # by users) to create the managed_installs virtual attribute
      def managed_installs
        installs + user_installs
      end

      # Concatentates installs (specified by admins) and user installs (specified
      # by users) to create the managed_installs virtual attribute
      def managed_uninstalls
        uninstalls + user_uninstalls
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
      
      def to_s(format = nil)
        case format
          when :unique then "#{id}_#{name}"
          when :path then "#{self.class.to_s.pluralize.tableize}/#{self.to_s(:unique)}"
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
        h[:managed_installs] = managed_installs.collect(&:to_s)
        h[:managed_uninstalls] = managed_uninstalls.collect(&:to_s)
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
          a << "#{computer_group.to_s(:path)}.plist"
        end
        a
      end
      
      # Attempts a couple different queries in order of importance to
      # find the appropriate record for the show action
      def self.find_for_show(s)
        # Find by ID
        record = self.where(:id => s).first
        # Find by id-name
        match = s.match(/(\d+)(-)(.+)(\.plist)/)
        if record.nil? and match.class == Array
          id = match[1]
          name = match[3]
          record ||= self.where(:id => id, :name => name).first
        end
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
        bundle_options = Bundle.unit_member(model_obj).collect { |e| [e.name,e.id] }
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
          :selected_options => model_obj.uninstalls_package_branch_ids }]
      end
      
      # Return the default record
      # Requires a unit to be passed
      def self.default(unit)
        r = self.unit(unit).find_by_name("Default")
        r ||= self.unit(unit).find_by_name("default")
        r ||= self.unit(unit).first
      end
      
      # ===================
      # = Code ends here! =
      # ===================
    end
  end
end