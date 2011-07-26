# Special ActiveRecord::Base mixin module
module Item
  # Used to augment the class definition
  # of the class passed as an argument
  # Put class customization in here!
  def self.extend_class(k)
    k.class_exec do
      # ====================
      # = Code start here! =
      # ====================
      
      belongs_to :manifest, :polymorphic => true # package, computer, computer group, bundle
      belongs_to :package_branch
      belongs_to :package
      
      # Returns the appropriate package for this package branch
      # relationship.  It does this by first checking if a package
      # ID is specified, grabbing a package if it exists.  If that fails
      # it grabs the latest package from the package branch and returns that
      def package
        # p = super
        p = Package.where(:id => package_id).first if package_id?
        
        p ||= package_branch.latest(manifest) if package_branch.present?
        p
      end
      
      # Returns array of versions for use with options_for_select view method
      def versions_for_select(unit_member)
        static_options = [['Most Recent','']]
        pb = package_branch
        pb.bind_to_scope(unit_member)
        dynamic_options = pb.packages.map {|p| [p.version, p.id]}
        static_options + dynamic_options
      end
      
      # ===================
      # = Code ends here! =
      # ===================
    end
  end
end