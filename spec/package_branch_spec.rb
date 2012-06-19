require 'spec_helper'

describe PackageBranch do
  before(:all) do
    module VersionTracker::Backgrounder
      def call_rake(*args)
      end
      
      extend self
    end
  end
  
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
  
  describe ".shared" do
    it "returns package branch records with associated package records with sharing enabled" do
      branch1 = FactoryGirl.create(:package_branch)
      branch2 = FactoryGirl.create(:package_branch)
      shared_package = FactoryGirl.create(:package, :package_branch_id => branch1.id, :shared => true)
      package = FactoryGirl.create(:package, :package_branch_id => branch2.id)
      shared_branches = PackageBranch.shared
      
      shared_branches.count.should == 1
      shared_branches.first.id.should == shared_package.id
    end
  end
  
  describe ".shared_packages" do
    it "returns associated package records that are shared" do
      branch = FactoryGirl.create(:package_branch)
      2.times { FactoryGirl.create(:package, :package_branch_id => branch.id) }
      2.times { FactoryGirl.create(:package, :package_branch_id => branch.id, :shared => true) }
      branch.shared_packages.each {|package| package.should be_shared }
    end
  end
end