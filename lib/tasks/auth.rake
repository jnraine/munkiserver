namespace :auth do
  desc "Upgrades munkiserver to use role based access control"
  task :upgrade, :needs => :environment do
    puts "Migrating database to add roles"
    ENV['VERSION'] = 20110726132838
    Rake::Task['db:migrate'].invoke
    Rake::Task['bootstrap:roles'].invoke
    
    puts "Assigning roles to existing users"
    User.each do |user|
      user.roles << user.super_user ? Role.admin : Role.super_user
    end
    
    puts "Removing super_user field from Users"
    ENV['VERSION'] = nil
    Rake::Task['db:migrate'].reenable
    Rake::Task['db:migrate'].invoke
  end
end