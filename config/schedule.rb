# Use this file to easily define all of your cron jobs.
# run take task to check for updates every night at 11 pm

# default rails enviroment set to production, when deploy need to remove development settings
every [:sunday, :monday, :tuesday, :wednesday, :thursday], :at => '11:00pm' do  
  rake "packages:send_available_update_digest"
  rake "warranties:update_all"
  # rake "chore:inactive_primary_user_email_notification"
end