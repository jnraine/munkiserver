desc "Setup application after installation"
task :deploy, :needs => :environment do
  Rake::Task["setting:create"].invoke
  Rake::Task["db:migrate"].invoke
  Rake::Task["bootstrap:all"].invoke
end