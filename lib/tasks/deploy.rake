desc "Setup application after installation"
task :deploy => :environment do
  Rake::Task["db:migrate"].invoke
  Rake::Task["bootstrap:all"].invoke
end