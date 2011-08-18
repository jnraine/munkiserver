namespace :db do
  desc "Destroys, re-creates, and loads the database with fixtures.  Optionally, pass environment."
  task :reload => :environment do
    # puts "Destroying database..."
    # print `rake db:migrate VERSION=0 RAIL_ENV=#{ENV.environment}`
    # puts "Migrating database..."
    # print `rake db:migrate RAIL_ENV=#{args.environment}`
    # puts "Loading fixtures..."
    # print `rake db:fixtures:load RAIL_ENV=#{args.environment}`
    # `rake init:models RAIL_ENV=#{ENV.enviro}`
    ENV["VERSION"] = "0"
    puts "Destroying database..."
    Rake::Task["db:migrate"].invoke()
    ENV["VERSION"] = nil
    sleep 2
    puts "Migrating database..."
    Rake::Task["db:migrate"].invoke()
    sleep 2
    puts "Loading fixtures..."
    Rake::Task["db:fixtures:load"].invoke()
    puts "Bootstraping models..."
    Rake::Task["bootstrap:all"].invoke()
  end
end

# ENV cascades down to other tasks
# Arguments are specified at invoke
# namespace :test do
#   task :args, :first, :second, :third, :needs => :environment do |t,args|
#     debugger
#     puts "We made it"
#   end
#   
#   task :call, :needs => :environment do |t, args|
#     Rake::Task["test:invoke"].invoke(1,2)
#   end
#   
#   task :invoke, :first, :second, :needs => :environment do |t, args|
#     debugger
#     puts "We are invoking"
#   end
# end