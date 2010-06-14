namespace :packages do  
  desc "Check versiontracker.com for available updates"
  task :check_for_updates => :environment do
    VersionTracker.update_all
  end
end