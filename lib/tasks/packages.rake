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
    version_trackers = VersionTracker.where(:web_id => nil)
    version_trackers.each do |version_tracker|
      print "Searching for #{version_tracker.package_branch} web ID..."
      version_tracker.retrieve_web_id
      puts version_tracker.web_id
      version_tracker.save
    end
    VersionTracker.update_all
  end
end