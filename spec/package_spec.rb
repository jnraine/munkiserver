require 'spec_helper'

describe Package do
  describe ".clone_package" do
    it "returns an unsaved package record with attributes matching target packages" do
      branch = FactoryGirl.create(:package_branch, :name => "Foo")
      target = FactoryGirl.create(:package, :package_branch_id => branch.id, :version => "1.0")
      unit = FactoryGirl.create(:unit)

      clone = Package.clone_package(target, unit)
      clone.should be_new_record
      clone.version.should == target.version
      clone.package_branch.name.should == branch.name
    end
  end
  
  describe "#cloneable_attributes" do
    it "should return a hash containing the value of clone attributes" do      
      FactoryGirl.build(:package).cloneable_attributes.keys.should == Package.clone_attributes
    end
  end
end