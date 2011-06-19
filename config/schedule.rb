# Use this file to easily define all of your cron jobs.
# run take task to check for updates every night at 11 pm
every 1.day, :at => '11:00pm' do
  rake "packages:check_for_updates"
end

# Learn more: http://github.com/javan/whenever
