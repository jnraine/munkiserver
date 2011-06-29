namespace :chore do
  desc "Removes all unused (unreferenced) SystemProfile records."
  task :cleanup_system_profiles => :environment do
    results = SystemProfile.unused.map(&:destroy)
    total = results.count
    failed = results.delete_if {|e| e}.count
    puts "Destroyed #{total - failed} out of #{total} unused system profile records"
  end
end