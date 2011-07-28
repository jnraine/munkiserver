namespace :auth do
  desc "Upgrades munkiserver to use role based access control"
  task :upgrade, :needs => :environment do
    primary_db_version    = 20110726132838
    if ActiveRecord::Migrator.current_version > primary_db_version
      puts "Roles have already been applied - Nothing to be done."
    else    
      puts "Migrating database to add roles"
      ENV['VERSION'] = primary_db_version.to_s
      Rake::Task['db:migrate'].invoke
      Rake::Task['bootstrap:roles'].invoke
    
      puts "Assigning roles to existing users"
      User.all.each do |user|
        if user.super_user
           user.roles << Role.admin
        else
          user.roles << Role.super_user
        end
      end
    
      puts "Removing super_user field from Users"
      ENV['VERSION'] = nil
      Rake::Task['db:migrate'].reenable
      Rake::Task['db:migrate'].invoke
    end
  end
end