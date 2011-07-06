require 'nokogiri'  
require 'open-uri'
MAC_UPDATE_SEARCH_URL = "http://www.macupdate.com/find/mac/" #append search package name in the end of URL
MAC_UPDATE_PACKAGE_URL = "http://www.macupdate.com/app/mac/" #append web_id in the end of URL
MAC_UPDATE_SITE_URL = "www.macupdate.com" #for Net HTTP response

namespace :packages do  
  desc "Check macupdate.com for available updates"
  task :check_for_updates => :environment do
    VersionTracker.update_all
  end
  
  
  desc "Check macupdate.com for available updates and notify Admins"
  task :send_update_notifications => :environment do
    VersionTracker.update_all
    
    PackageBranch.available_updates.each do |package|
      AdminMailer.package_update_available(package).deliver
    end
  end
  
  desc "Autotmaically scan each package and assgin a Macupdate Web ID"
  task :scan => :environment do
    packages = Package.all
    packages.each do |package|
      info_doc = Nokogiri::HTML(open(MAC_UPDATE_SEARCH_URL + package.name))
      # if macupdate return a search page
      if info_doc.css("span:nth-child(1)").text.include?("Search")
        href_match = info_doc.css(".titlelink").first[:href].match(/([0-9]{4,})/) if info_doc.css(".titlelink").first[:href].present?
        if href_match.present?
           package.version_tracker_web_id = href_match[1]
           package.save
        end
      end
    end
    VersionTracker.update_all
  end
end