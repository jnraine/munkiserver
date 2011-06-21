class VersionTracker < ActiveRecord::Base
  require 'nokogiri'  
  require 'open-uri'
  require 'net/http'

  # MAC_UPDATE_SEARCH_URL = "http://www.macupdate.com/find/mac/" #append search package name in the end of URL
  MAC_UPDATE_PACKAGE_URL = "http://www.macupdate.com/app/mac/" #append web_id in the end of URL
  MAC_UPDATE_SITE_URL = "www.macupdate.com" #for Net HTTP response
  
  
  belongs_to :package_branch
  belongs_to :icon

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
    MAC_UPDATE_PACKAGE_URL + "#{web_id}"
  end
  
  # Scrapes latest version from macupdate.com and updates record with that info
  def scrape_latest_version
    if looks_good?
      # Load informational page from version tracker
      info_doc = Nokogiri::HTML(open(info_url))
      # In case our web site is malformed, let's catch the errors
      begin
        # Grab app version
        latest_version = info_doc.at_css("#appversinfo").text
        # Grab the icon image
        icon_url = info_doc.at_css("#appiconinfo")[:src]
        # Grab download redirect url
        download_redirect_url = info_doc.at_css("#downloadlink")[:href]
        # Grab the description of the package
        description = info_doc.at_css("#desc").text
      rescue NoMethodError => e
        raise VersionTrackerError.new("Malformed version tracker website at #{info_url}: #{e}")
      end
      
      # read the HTTP header extract the value in "location" to the actual download url
      response = nil
      Net::HTTP.start(MAC_UPDATE_SITE_URL, 80) {|http|
        response = http.head(download_redirect_url)
      }
      
      # if package doesn't have an icon then scrape the icon from macupdate.com
      if self.icon.nil?
        scrape_icon(icon_url)
      end
      
      # Update record with latest information
      self.version = latest_version
      self.download_url = response['location']
      # strip down any white speace before and after the description string
      self.description = description.lstrip.rstrip
      self.save
      # Return results
      {'latest_version' => self.version, 'download_url' => self.download_url, 'description' => self.description}
      
    end
  end
  
  
  # get the package icon download url and download the icon
  def scrape_icon(icon_url)
    f = open(icon_url)
    original_filename = icon_url.match(/(\/)([^\/]+)$/)[2]
    # Temp stuff
    tmp_dir = Pathname.new(File.dirname(f.path))
    tmp_path = tmp_dir + original_filename
    # Rename temp file
    FileUtils.mv(f.path,tmp_path)
    # Close old file handle
    f.close
    # Open new file handle
    f = File.open(tmp_path)
    self.icon = Icon.new({:photo => f})
    self.save
  end
  
  
  # Turns the version tracker instance into a package object by way of magic. Package record is unsaved and needs a unit before saving!
  # Scrapes the latest version of the package before packaging
  def to_package
    self.scrape_latest_version
    AutoPackage.from_url(download_url)
  end
  
  def web_id=(value)
    super(value)
  end 
  
  
end

