require 'spec_helper'

describe PackageBranch do
  describe "#version_tracker_web_id" do
    it "returns the web ID of the associated version tracker", :vcr do
      branch = FactoryGirl.create(:package_branch)
      version_tracker = VersionTracker.create!(:package_branch_id => branch.id, :web_id => 10700)
      branch.version_tracker_web_id.should == 10700
    end
  end
  
  describe "#version_tracker_web_id=" do
    it "sets the web ID of the associated version tracker", :vcr do
      branch = FactoryGirl.create(:package_branch)
      version_tracker = VersionTracker.create!(:package_branch_id => branch.id, :web_id => 10700)
      branch.version_tracker_web_id = 100
      branch.version_tracker_web_id.should == 100
    end
  end
end