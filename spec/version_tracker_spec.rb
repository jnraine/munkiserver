require 'spec_helper'

describe VersionTracker, :vcr do
  let(:firefox_page) { NokogiriHelper.page("http://www.macupdate.com/app/mac/10700/firefox") }
  let(:google_page) { NokogiriHelper.page("http://www.google.com") }
  
  describe "#fetch_data" do
    context "given a package branch with a perfect macupdate.com page" do
      it "fetches and assigns all kinds of stuff" do
        branch = FactoryGirl.create(:package_branch, :display_name => "Firefox")
        tracker = VersionTracker.new do |t|
          t.package_branch = branch
        end
        
        tracker.fetch_data
        [tracker.icon, tracker.description, tracker.version, tracker.download_links].each do |attr|
          attr.should be_present
        end
      end
    end
  end
  
  describe "#retrieve_web_id" do
    context "given a package branch name with results on macupdate.com" do
      it "returns a web ID" do
        branch = FactoryGirl.create(:package_branch, :display_name => "Firefox")
        version_tracker = VersionTracker.new do |vt|
          vt.package_branch = branch
        end
        version_tracker.retrieve_web_id.should == 10700
      end
    end
    
    context "given a package branch name with no results on macupdate.com" do
      it "returns nil" do
        branch = FactoryGirl.create(:package_branch, :display_name => "abcd")
        version_tracker = VersionTracker.new do |vt|
          vt.package_branch = branch
        end
        version_tracker.retrieve_web_id.should be_nil
      end
    end
  end
  
  describe "#scrape_data" do
    context "given a page with version and description" do
      it "scrapes data from macupdate.com and returns hash" do
        data = VersionTracker.new.scrape_data(firefox_page)
        data[:version].should be_present
        data[:description].should be_present
      end
    end
    
    context "given a page without version or description" do
      it "scrapes data from macupdate.com and returns hash" do
        data = VersionTracker.new.scrape_data(google_page)
        data[:version].should be_blank
        data[:description].should be_blank
      end
    end
  end
  
  describe "#scrape_download_links" do
    context "given a page with download links" do
      it "scrapes download link elements and returns an array of unsaved DownloadLink objects" do
        download_links = VersionTracker.new.scrape_download_links(firefox_page)
        download_links.each {|download_link| download_link.should be_a DownloadLink }
        download_links.first.should be_new_record
      end
    end
    
    context "given a page without download links" do
      it "returns an empty array" do
        version_tracker = VersionTracker.new
        download_links = version_tracker.scrape_download_links(NokogiriHelper.page("http://google.com"))
        download_links.should be_empty
      end
    end
  end
  
  describe "#scrape_icon" do
    context "given a page with an icon" do
      it "returns an unsaved icon" do
        icon = VersionTracker.new.scrape_icon(firefox_page)
        icon.should be_an(Icon)
        icon.should be_new_record
      end
    end
    
    context "given a page with no icon" do
      it "returns nil" do
        VersionTracker.new.scrape_icon(google_page).should be_nil
      end
    end
  end
end