namespace :db do
  desc "Destroys, re-creates, and loads the database with fixtures"
  task :reload do
    puts "Destroying database..."
    print `rake db:migrate VERSION=0`
    puts "Migrating database..."
    print `rake db:migrate`
    puts "Loading fixtures..."
    print `rake db:fixtures:load`
    `rake init:models`
  end
end