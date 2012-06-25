class MigratePackageBranches
  attr_accessor :log
  
  def initialize(log = NullObject.new)
    @log = log
  end
  
  def migrate
    reassign_packages
    reassign_manifest_items
    destroy_obsolete_branches
  end
  
  def destroy_obsolete_branches
    PackageBranch.all.each do |b| 
      if b.obsolete?
        log.info "Destroying obsolete branch: #{b.inspect}"
        b.destroy
      end
    end
  end
  
  def destroy_obsolete_items
    all_items.each do |item| 
      if item.obsolete?
        log.info "Destroying obsolete item: #{item.inspect}"
        item.destroy
      end
    end
  end
  
  # Reassigns manifest items on nil unit package branches
  def reassign_manifest_items
    destroy_obsolete_items
    
    all_items.each do |item|
      if item.package_branch.unit.nil?
        log.info "Reassigning #{item.inspect}"
        nil_unit_branch = item.package_branch
        raise item.inspect if item.manifest.nil?
        unit_scoped_branch = retrieve_unit_scoped_branch(nil_unit_branch, item.manifest.unit)
        item.package_branch = unit_scoped_branch
        item.save!
        log.info "\t #{item.inspect}"
      end
    end
  end
  
  def all_items
    [InstallItem, UninstallItem, ManagedUpdateItem, OptionalInstallItem, RequireItem, UpdateForItem].map(&:all).flatten
  end
  
  def retrieve_unit_scoped_branch(nil_unit_branch, unit, category = nil)
    category ||= PackageCategory.default
    branch = PackageBranch.where(:unit_id => unit.id, :name => nil_unit_branch.name).first
    branch ||= PackageBranch.new do |b|
      b.unit_id = unit.id
      b.name = nil_unit_branch.name
      b.display_name = nil_unit_branch.display_name
      b.package_category_id = category.id
    end
    
    branch.save! if branch.new_record?
    
    branch
  end
  
  # Creates a package branch scoped to a unit for each package. If a package 
  # branch already exists for that particular unit, it is assigned to the package instead.
  def reassign_packages
    Package.all.each do |package|
      original_branch = package.package_branch
      if original_branch.unit.blank?
        log.info "Migrating #{package.to_s(:pretty_with_version)}'s package branch..."

        new_branch = retrieve_unit_scoped_branch(original_branch, package.unit, PackageCategory.where(:id => package.package_category_id).first)
        package.package_branch = new_branch
        package.save!
        
        log.info "ok"
      end
    end
  end
end