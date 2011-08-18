namespace :packages do  
  desc "Check macupdate.com for available updates"
  task :check_for_updates => :environment do
    VersionTracker.update_all
  end
  
  
  desc "Check macupdate.com for available updates and notify Admins (one email per package)"
  task :send_update_notifications => :environment do
    VersionTracker.update_all    
    PackageBranch.available_updates.each do |package|
      AdminMailer.package_update_available(package).deliver
    end
  end
  
  desc "Send available package updates digest email"
  task :send_available_update_digest => :environment do
    VersionTracker.update_all
    Unit.all.each do |unit|
      # Send email notification only when there is more than one package available for update
      if PackageBranch.available_updates(unit).count > 0
        AdminMailer.available_updates_digest(unit).deliver
      end
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
  end
  
  desc "Conform package branch name to contraints" 
  task :conform_names => :environment do
    PackageBranch.all.each do |pb|
      original_name = pb.name
      conformed_name = PackageBranch.conform_to_name_constraints(original_name)
      if original_name != conformed_name
        print "Conforming #{original_name} to #{conformed_name} for package branch ID #{pb.id}"
        pb.name = conformed_name
        if pb.save
          puts "OK"
        else
          puts "failed!"
        end
      end
    end
  end
end