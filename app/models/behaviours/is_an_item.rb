module IsAnItem
  def self.included(base)
    base.extend ClassMethods
    
    base.class_eval do
      belongs_to :manifest, :polymorphic => true # package, computer, computer group, bundle
      belongs_to :package_branch
      belongs_to :package
    end
  end
  
  module ClassMethods
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
  end

  def package
    p = Package.where(:id => package_id).first if package_id.present?
    p ||= package_branch.packages.group_by {|p| p.environment_id }[manifest.environment_id].first if package_branch.present?
    p
  end
  
  def obsolete?
    manifest.nil?
  end
   
  # Returns array of versions for use with options_for_select view method
  def versions_for_select(unit_member)
    static_options = [['Most Recent','']]
    dynamic_options = package_branch.packages.map {|p| [p.version, p.id]}
    static_options + dynamic_options
  end
end