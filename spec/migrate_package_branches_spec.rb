require 'spec_helper'

describe MigratePackageBranches do
  let(:nil_unit_branch) do
    nil_unit_branch = FactoryGirl.build(:package_branch, :unit_id => nil)
    nil_unit_branch.save(:validate => false)
    nil_unit_branch
  end
  
  describe "#retrieve_unit_scoped_branch" do
    context "when a unit-scoped branch doesn't exist" do
      it "should create a new branch that is unit scoped and return it" do
        unit = FactoryGirl.create(:unit)
        category = FactoryGirl.create(:package_category)
        unit_scoped_branch = MigratePackageBranches.new.retrieve_unit_scoped_branch(nil_unit_branch, unit, category)
        unit_scoped_branch.tap do |b|
          b.should_not be_new_record
          b.unit.id.should == unit.id
          b.attributes == nil_unit_branch.attributes
          b.package_category_id.should == category.id
        end
      end
    end
    
    context "when a unit-scoped branch exists" do
      it "should retrieve a branch that is unit scoped and return it" do
        unit = FactoryGirl.create(:unit)
        category = FactoryGirl.create(:package_category)
        existing_unit_scoped_branch = FactoryGirl.create(:package_branch, :unit => unit, :name => nil_unit_branch.name)
        unit_scoped_branch = MigratePackageBranches.new.retrieve_unit_scoped_branch(nil_unit_branch, unit, category)
        unit_scoped_branch.id.should == existing_unit_scoped_branch.id
      end
    end
    
  end
  
  describe "#reassign_packages" do
    it "should create package branches associated with each package's unit, then be assigned to the package" do
      package = FactoryGirl.create(:package, :package_branch => nil_unit_branch)
      
      MigratePackageBranches.new.reassign_packages
      
      package.reload
      package.package_branch.id.should_not == nil_unit_branch.id
      package.package_branch.unit.should_not be_nil
    end
  end
  
  describe "#reassign_manifest_items" do
    it "reassigns install items to unit-scoped branch records" do
      FactoryGirl.create(:package_category)
      computer = FactoryGirl.create(:computer)
      item = computer.install_items.create!(:package_branch => nil_unit_branch)

      MigratePackageBranches.new.reassign_manifest_items
      nil_unit_branch.install_items.should be_empty
      item.reload.package_branch.unit.should == item.manifest.unit
    end
    
    it "reassigns uninstall items to unit-scoped branch records" do
      FactoryGirl.create(:package_category)
      computer = FactoryGirl.create(:computer)
      item = computer.uninstall_items.create!(:package_branch => nil_unit_branch)

      MigratePackageBranches.new.reassign_manifest_items
      nil_unit_branch.uninstall_items.should be_empty
      item.reload.package_branch.unit.id.should == item.manifest.unit.id
    end
    
    it "reassigns managed update items to unit-scoped branch records" do
      FactoryGirl.create(:package_category)
      computer = FactoryGirl.create(:computer)
      item = computer.managed_update_items.create!(:package_branch => nil_unit_branch)

      MigratePackageBranches.new.reassign_manifest_items
      nil_unit_branch.managed_update_items.should be_empty
      item.reload.package_branch.unit.should == item.manifest.unit
    end
    
    it "reassigns optional install items to unit-scoped branch records" do
      FactoryGirl.create(:package_category)
      computer = FactoryGirl.create(:computer)
      item = computer.optional_install_items.create!(:package_branch => nil_unit_branch)

      MigratePackageBranches.new.reassign_manifest_items
      nil_unit_branch.optional_install_items.should be_empty
      item.reload.package_branch.unit.should == item.manifest.unit
    end
    
    it "reassigns require items to unit-scoped branch records" do
      FactoryGirl.create(:package_category)
      package = FactoryGirl.create(:package)
      item = package.require_items.create!(:package_branch => nil_unit_branch)

      MigratePackageBranches.new.reassign_manifest_items
      nil_unit_branch.require_items.should be_empty
      item.reload.package_branch.unit.should == item.manifest.unit
    end
    
    it "reassigns update for items to unit-scoped branch records" do
      FactoryGirl.create(:package_category)
      package = FactoryGirl.create(:package)
      item = package.update_for_items.create!(:package_branch => nil_unit_branch)

      MigratePackageBranches.new.reassign_manifest_items
      nil_unit_branch.update_for_items.should be_empty
      item.reload.package_branch.unit.should == item.manifest.unit
    end
  end
  
  describe "#destroy_obsolete_branches" do
    let(:obsolete_branch) { nil_unit_branch }
    let(:active_branch) do
      branch = FactoryGirl.create(:package_branch)
      package = FactoryGirl.create(:package, :unit => branch.unit, :package_branch => branch)
    end
    
    it "removes obsolete branches" do
      obsolete_branch
      active_branch
      MigratePackageBranches.new.destroy_obsolete_branches
      lambda { obsolete_branch.reload }.should raise_error(ActiveRecord::RecordNotFound)
      lambda { active_branch.reload }.should_not raise_error(ActiveRecord::RecordNotFound)
    end
  end
end


