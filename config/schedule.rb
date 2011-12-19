# Use this file to easily define all of your cron jobs.

# default rails enviroment set to production, when deploy need to remove development settings

# run rake tasks to check for updates every night at 11 pm
every 1.day, :at => '11:00pm' do  
  rake "packages:send_available_update_digest"
  rake "warranties:update_all"
end

# run rake tasks to cleanup old system profiles, managed install reports, and missing manifets
# every night at 12 pm 
every 1.day, :at => '2:00am' do
  rake "chore:cleanup_system_profiles"
  rake "chore:cleanup_old_managed_install_report"
  rake "chore:cleanup_missing_manifests"
end