class VersionTracker < ActiveRecord::Base
  require 'nokogiri'  
  require 'open-uri'

  VERSION_TRACKER_URL = "http://www.versiontracker.com/dyn/moreinfo/macosx"

  belongs_to :package_branch

  def self.update_all
    # Get all trackable packages branches
    pbs = PackageBranch.all
    pbs.each do |pb|
      pb.version_tracker.scrape_latest_version unless pb.version_tracker.nil?
      pb.save
    end
  end
  
  # Returns true if the record "looks" like it points to a valid version tracker source
  def looks_good?
    # Web ID is only digits
    web_id.to_s.match(/^\d+$/) != nil
  end
  
  # URL to version tracker page
  def info_url
    VERSION_TRACKER_URL + "/#{web_id}"
  end
  
  # Scrapes latest version from versiontracker.com and updates record with that info
  def scrape_latest_version
    if looks_good?
      # Load informational page from version tracker
      info_doc = Nokogiri::HTML(open(info_url))
      # In case our web site is malformed, let's catch the errors
      begin
        # Grab app version
        latest_version = info_doc.at_css(".appVersion").text
        # Grab download redirect url
        download_redirect_url = info_doc.at_css(".product-quick-links h2 a")[:href]
      rescue NoMethodError => e
        raise VersionTrackerError.new("Malformed version tracker website at #{info_url}: #{e}")
      end
      
      # Grab download url
      unless download_redirect_url == nil
        # Replace spaces with encoding (%20)
        download_redirect_url = download_redirect_url.gsub(" ","%20")
        download_doc = Nokogiri::HTML(open(download_redirect_url))
        self.download_url = download_doc.at_css("p.contactDevSite a")[:href]
      else
        self.download_url = nil
      end
    
      # Update record with latest information
      self.version = latest_version
      self.download_url = download_url
      # Return results
      {'latest_version' => self.version, 'download_url' => self.download_url}
    end
  end
  
  # Turns the version tracker instance into a package object by way of magic. Package record is unsaved and needs a unit before saving!
  # Scrapes the latest version of the package before packaging
  def to_package
    self.scrape_latest_version
    AutoPackage.from_url(download_url)
  end
end
