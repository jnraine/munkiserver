# Use this file to easily define all of your cron jobs.
# run take task to check for updates every night at 11 pm

# default rails enviroment set to production, when deploy need to remove development settings
every 1.day, :at => '11:00pm' do  
  rake "packages:send_update_notifications"
end
# Learn more: http://github.com/javan/whenever
