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
      
      belongs_to :manifest, :polymorphic => true
      belongs_to :package_branch
      
      # Returns the appropriate package for this package branch
      # relationship.  It does this by first checking if a package
      # ID is specified, grabbing a package if it exists.  If that fails
      # it grabs the latest package from the package branch and returns that
      def package
        p = Package.find(package_id) if package_id?
        p ||= package_branch.latest
        p
      end
      
      # ===================
      # = Code ends here! =
      # ===================
    end
  end
end