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
        p = Package.where(:id => self.package_id).first
        p ||= package_branch.latest(manifest) if package_branch.present?
        p
      end
      #       
      # Returns array of versions for use with options_for_select view method
      def versions_for_select(unit_member)
        static_options = [['Most Recent','']]
        pb = package_branch
        pb.bind_to_scope(unit_member)
        dynamic_options = pb.packages.map {|p| [p.version, p.id]}
        static_options + dynamic_options
      end
      
      def self.destroy_stale_records
        Rails.logger.info "Destroying #{self.to_s} records with nil package reference..."
        records_with_nil_packages.map do |item|
          Rails.logger.info "Destroying item.inspect"
          item.destroy
        end
      end
      
      def self.records_with_nil_packages
        self.all.delete_if {|item| item.present? }
      end
      
      # ===================
      # = Code ends here! =
      # ===================
    end
  end
end