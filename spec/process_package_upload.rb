require 'spec_helper'

describe ProcessPackageUpload do
  describe "#retrieve_package_branch" do
    context "given a suitable package branch doesn't exist yet" do
      it "takes a hash of attributes and returns a package branch" do
        unit = FactoryGirl.create(:unit)
        category = FactoryGirl.create(:package_category)
        environment = FactoryGirl.create(:environment)
        attributes = {:name => "Foo", :display_name => "Foo App", :unit_id => unit.id, :package_category_id => category.id}
        branch = ProcessPackageUpload::PackageAssembler.retrieve_package_branch(attributes)

        branch.name.should == "foo"
        branch.unit_id.should == unit.id
        branch.display_name.should == "Foo App"
        branch.package_category_id.should == category.id
      end
    end
  end
end