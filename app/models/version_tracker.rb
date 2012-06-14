require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'cgi'

class VersionTracker < ActiveRecord::Base
  MAC_UPDATE_SITE_URL = "http://www.macupdate.com"
  MAC_UPDATE_SEARCH_URL = "#{MAC_UPDATE_SITE_URL}/find/mac/"
  MAC_UPDATE_PACKAGE_URL = "#{MAC_UPDATE_SITE_URL}/app/mac/"
  
  has_many :download_links, :dependent => :destroy, :autosave => true
  
  belongs_to :package_branch
  belongs_to :icon, :dependent => :destroy, :autosave => true
  
  after_save :refresh_data
  after_create :background_fetch_data
  
  def self.update_all
    branches = PackageBranch.all
    branches.each do |branch|
      branch.version_tracker.fetch_data
      branch.save!
    end
  end
  
  def self.fetch_data(id)
    tracker = VersionTracker.where(:id => id).first
    if tracker.present?
      tracker.fetch_data
      tracker.save!
      tracker
    end
  end
  
  def refresh_data
    background_fetch_data if web_id_changed?
  end
  
  def background_fetch_data
    Backgrounder.call_rake("chore:fetch_version_tracker_data", :id => id)
  end
  
  def fetch_data
    self.web_id = retrieve_web_id if web_id.blank?
    page = NokogiriHelper.page(page_url)
    self.assign_data(scrape_data(page))
    self.icon = scrape_icon(page)
    self.download_links = scrape_download_links(page)

    self
  end
  
  def assign_data(data)
    self.version = data[:version].to_s
    self.description = data[:description].to_s
  end
  
  # Return true if macupdate is reachable
  def macupdate_is_up?
    begin
      response = Net::HTTP.get_response(URI.parse(MAC_UPDATE_SITE_URL))
      response.instance_of?(Net::HTTPOK)
    rescue SocketError, Errno::ETIMEDOUT, Errno::ECONNREFUSED
      return false
    end
  end
  
  # URL to version tracker page
  def page_url
    MAC_UPDATE_PACKAGE_URL + "#{web_id}"
  end
  
  # Get all the download link and it's attributes
  def scrape_download_links(page)
    download_links = []
    page.css("#downloadlink").each do |link_element|
      download_url = NokogiriHelper.redirect_url(MAC_UPDATE_SITE_URL + link_element[:href])
      caption = link_element.parent().css(".info").text.lstrip.rstrip        
      text = link_element.text
      download_links << self.download_links.build({:text => text, :url => download_url, :caption => caption})
    end
    
    download_links
  end
  
  # Scrapes latest version from macupdate.com and return results
  def scrape_data(page, options = {})
    options = {:refresh_icon => false}.merge(options)
    {:version => NullObject.Maybe(page.at_css("#appversinfo")).text, :description => NullObject.Maybe(page.at_css("#desc")).text.lstrip.rstrip }
  end
  
  # Get the package icon download url and download the icon
  def scrape_icon(page)
    if image_element = page.at_css("#appiconinfo")
      url_string = image_element[:src]
      url = URI.parse(url_string)
      response_body = Net::HTTP.get_response(url).body
      image_file = Tempfile.new("icon", :encoding => response_body.encoding.name)
      image_file.write(response_body)
      icon = Icon.new({:photo => image_file})
      if icon.save
        icon
      else
        nil
      end
    end
  end

  # Retrieves and returns web ID of first search result
  def retrieve_web_id
    if macupdate_is_up?
      page = NokogiriHelper.page(MAC_UPDATE_SEARCH_URL + package_branch.display_name)
      link = page.css(".titlelink").first
      if link.present?
        url = link[:href]
        url.match(/([0-9]{4,})/)[1].to_i
      end
    end
  end
end

