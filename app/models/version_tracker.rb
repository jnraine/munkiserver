class VersionTracker < ActiveRecord::Base
  require 'nokogiri'  
  require 'open-uri'
  require 'net/http'

  MAC_UPDATE_SITE_URL = "www.macupdate.com" #for Net HTTP response
  MAC_UPDATE_SEARCH_URL = "http://www.macupdate.com/find/mac/" #append search package name in the end of URL
  MAC_UPDATE_PACKAGE_URL = "http://www.macupdate.com/app/mac/" #append web_id in the end of URL
  
  # validates_presence_of :package_branch_id
  
  has_many :download_links, :dependent => :destroy, :autosave => true
  
  belongs_to :package_branch
  belongs_to :icon
  
  before_save :scrape_latest_version_if_web_id_changed
  before_create :retrieve_web_id, :scrape_latest_version
  
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
    web_id.to_s.match(/^\d+$/) != nil and info_url_exists? and macupdate_is_up?
  end
  
  # Return true if the macupdate.com url exists
  def info_url_exists?
    begin
      response = Net::HTTP.get_response(URI.parse(info_url))
      response.instance_of?(Net::HTTPOK) or response["location"].nil? or response["location"].match(/#{info_url}/).present?
    rescue SocketError
      return false
    rescue Errno::ETIMEDOUT # occurs on RHEL, not sure why
      return false
    rescue Errno::ECONNREFUSED # server refused to connect
      return false
    end
  end
  
  # Return true if macupdate is reachable
  def macupdate_is_up?
    begin
      response = Net::HTTP.get_response(URI.parse("http://"+MAC_UPDATE_SITE_URL))
      response.instance_of?(Net::HTTPOK)
    rescue SocketError # DNS name not found
      return false
    rescue Errno::ETIMEDOUT # occurs on RHEL, not sure why
      return false
    rescue Errno::ECONNREFUSED # server refused to connect
      return false
    end
  end
  
  # URL to version tracker page
  def info_url
    MAC_UPDATE_PACKAGE_URL + "#{web_id}"
  end
  
  # Get all the download link and it's attributes
  def get_download_links(info_doc)
    self.download_links = []
    if info_doc.css("#downloadlink").count != 0
      info_doc.css("#downloadlink").each do |download_link|
        text = download_link.text
        download_redirect_url = download_link[:href]
        # read the HTTP header extract the value in "location" to the actual download url
        response = nil
          if !download_redirect_url.empty?
            Net::HTTP.start(MAC_UPDATE_SITE_URL, 80) do |http|
              response = http.head(download_redirect_url)
            end
          end
        url = response['location']
        caption = download_link.parent().css(".info").text.lstrip.rstrip
        self.download_links << self.download_links.build({:text => text, :url => url, :caption => caption})
      end
    end
  end
  
  # Scrapes latest version from macupdate.com and updates record with that info
  def scrape_latest_version(new_web_id = false)
    if looks_good?
      # Load informational page from version tracker
      info_doc = Nokogiri::HTML(open(info_url))
      # In case our web site is malformed, let's catch the errors
      begin
        # Grab the icon image
        icon_url = info_doc.at_css("#appiconinfo")[:src]
        # Grab all the download links available
        get_download_links(info_doc)
        latest_version = nil
        # If there exists a download link that contains the stable version number
        # Get latest version number from the download link
        download_links.each do |downloadlink|
          if downloadlink.caption.include?("Stable")
            match = downloadlink.text.match(/[0-9.]+/) if downloadlink.text.present?
            latest_version = match[0] if match.present?
          end
        end
        latest_version ||= info_doc.at_css("#appversinfo").text
        # Grab the description of the package
        description = info_doc.at_css("#desc").text
      rescue NoMethodError => e
        raise VersionTrackerError.new("Malformed version tracker website at #{info_url}: #{e}")
      end
      
      # If package doesn't have an icon then scrape the icon from macupdate.com
      if self.icon.nil? or new_web_id
        self.icon = scrape_icon(icon_url)
      end
      # Strip down any white speace before and after the description string
      self.description = description.lstrip.rstrip
      self.version = latest_version
      # Return results
      {'latest_version' => self.version, 'description' => self.description}
    else
      # Reset the values associated to the version tracker to nil if the value is blank
      self.version = nil
      self.description = nil
      self.icon.destroy unless self.icon.nil?
      self.icon_id = nil
      self.download_links = []
    end
  end
  
  # Get the package icon download url and download the icon
  def scrape_icon(icon_url)
    original_filename = icon_url.match(/(\/)([^\/]+)$/)[2]
    f = open(icon_url)
    if f.instance_of?(StringIO)
      image_data = f
      f = Tempfile.new(original_filename)
      f.write(image_data.string.to_utf8)
    end
    # Temp stuff
    tmp_dir = Pathname.new(File.dirname(f.path))
    tmp_path = tmp_dir + original_filename
    # Rename temp file
    FileUtils.mv(f.path,tmp_path)
    # Close old file handle
    f.close
    # Open new file handle
    f = File.open(tmp_path)
    icon = Icon.new({:photo => f})
    icon.save
    icon
  end
  
  # Used as a before_save filter to ensure new info is pulled 
  # when the web_id is changed.
  def scrape_latest_version_if_web_id_changed
    scrape_latest_version(true) if web_id_changed?
  end
  
  # Turns the version tracker instance into a package object by way of magic. Package record is unsaved and needs a unit before saving!
  # Scrapes the latest version of the package before packaging
  def to_package
    self.scrape_latest_version
    AutoPackage.from_url(download_url)
  end

  # Retrieves and assigns the first web ID from a macupdate search
  def retrieve_web_id
    if macupdate_is_up?
      info_doc = Nokogiri::HTML(open(MAC_UPDATE_SEARCH_URL + self.package_branch.name))
      # if macupdate return a search page
      if info_doc.css(".titlelink").present?
        href_match = info_doc.css(".titlelink").first[:href].match(/([0-9]{4,})/) if info_doc.css(".titlelink").first.present?
        self.web_id = href_match[1] if href_match.present?
        # if macupdate redirect to the single page
      elsif info_doc.css("#listingarea script").text.include?("document.location")
        self.web_id = info_doc.css("#listingarea script").text.match(/([0-9]+{4,})/)[0].to_i unless info_doc.css("#listingarea script").text.match(/([0-9]+{4,})/).nil?
      else
        # do nothing
      end
    end
  end
end

