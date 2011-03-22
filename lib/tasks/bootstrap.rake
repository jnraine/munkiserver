namespace :bootstrap do
  desc "Call all the bootstrap tasks"
  task :all do
    tasks = tasks_in_namespace("bootstrap")
    tasks.each do |task|
      Rake::Task[task].invoke
      # Had some failing tasks, give them a second to breathe
      sleep 1
    end
  end
  
  # desc "Add a generic icon to the Icon model"
  # task :generic_icon => :environment do
  #   path = Rails.root.to_s + "/public/default_icons"
  #   i = Icon.new(:uploaded_data => LocalFile.new("#{path}/generic.png"))
  #   i.save
  # end
  
  desc "Intialize PackageCategory with default categories"
  task :package_categories => :environment do
    path = Rails.root.to_s + "/public/default_icons/package_categories"
    a = [{:name => "Misc", :icon_path => "#{path}/package.png"},
         {:name => "Application", :icon_path => "#{path}/application.png"},
         {:name => "Admin", :icon_path => "#{path}/admin.png"},
         {:name => "System", :icon_path => "#{path}/system.png"},
         {:name => "Utility", :icon_path => "#{path}/utility.png"}]
    # Add the records
    a.each do |h|
      r = PackageCategory.find_or_create_by_name(h[:name])
      # Add an icon if there isn't one already
      if r.icon.nil?
        f = File.new(h[:icon_path])
        i = Icon.new
        i.photo = f
        unless i.save
          puts "#{h[:name]} package category icon (#{h[:icon_path]}) failed to save: " + i.errors.inspect
        end
        r.icon = i
        f.close
      end
      unless r.save
        puts "#{h[:name]} package category failed to save: " + r.errors.inspect
      end
    end
  end
  
  desc "Initialize ComputerModel with Apple products"
  task :computer_models => :environment do
    path = Rails.root.to_s + "/public/default_icons/computer_models"
    a = [{:name => "eMac",:icon_path => "#{path}/com.apple.emac.png"},
         {:name => "iBook G4 (12-inch)",:icon_path => "#{path}/com.apple.ibook-g4-12.png"},
         {:name => "iBook G4 (14-inch)",:icon_path => "#{path}/com.apple.ibook-g4-14.png"},
         {:name => "iMac Aluminum (20-inch)",:icon_path => "#{path}/com.apple.imac-aluminum-20.png"},
         {:name => "iMac Aluminum (24-inch)",:icon_path => "#{path}/com.apple.imac-aluminum-24.png"},
         {:name => "iMac G4 (15-inch)",:icon_path => "#{path}/com.apple.imac-g4-15.png"},
         {:name => "iMac G4 (17-inch)",:icon_path => "#{path}/com.apple.imac-g4-17.png"},
         {:name => "iMac G4 (20-inch)",:icon_path => "#{path}/com.apple.imac-g4-20.png"},
         {:name => "iMac G5 (17-inch)",:icon_path => "#{path}/com.apple.imac-g5-17.png"},
         {:name => "iMac G5 (20-inch)",:icon_path => "#{path}/com.apple.imac-g5-20.png"},
         {:name => "iMac iSight (17-inch)",:icon_path => "#{path}/com.apple.imac-iSight-17.png"},
         {:name => "iMac iSight (20-inch)",:icon_path => "#{path}/com.apple.imac-iSight-20.png"},
         {:name => "iMac iSight (24-inch)",:icon_path => "#{path}/com.apple.imac-iSight-24.png"},
         {:name => "iMac Unibody (21-inch)",:icon_path => "#{path}/com.apple.imac-unibody-21.png"},
         {:name => "iMac Unibody (27-inch)",:icon_path => "#{path}/com.apple.imac-unibody-27.png"},
         {:name => "Default",:icon_path => "#{path}/com.apple.mac.png"},
         {:name => "MacBook Black",:icon_path => "#{path}/com.apple.macbook-black.png"},
         {:name => "MacBook White",:icon_path => "#{path}/com.apple.macbook-white.png"},
         {:name => "MacBook Unibody Plastic",:icon_path => "#{path}/com.apple.macbook-unibody-plastic.png"},
         {:name => "MacBook Unibody",:icon_path => "#{path}/com.apple.macbook-unibody.png"},
         {:name => "MacBook Air",:icon_path => "#{path}/com.apple.macbookair.png"},
         {:name => "MacBook Pro Unibody (13-inch)",:icon_path => "#{path}/com.apple.macbookpro-13-unibody.png"},
         {:name => "MacBook Pro Unibody (15-inch)",:icon_path => "#{path}/com.apple.macbookpro-15-unibody.png"},
         {:name => "MacBook Pro Unibody (17-inch)",:icon_path => "#{path}/com.apple.macbookpro-17-unibody.png"},
         {:name => "MacBook Pro (15-inch)",:icon_path => "#{path}/com.apple.macbookpro-15.png"},
         {:name => "MacBook Pro (17-inch)",:icon_path => "#{path}/com.apple.macbookpro-17.png"},
         {:name => "Mac mini server",:icon_path => "#{path}/com.apple.macmini-server.png"},
         {:name => "Mac mini",:icon_path => "#{path}/com.apple.macmini.png"},
         {:name => "Mac Pro",:icon_path => "#{path}/com.apple.macpro.png"},
         {:name => "PowerBook G4 (12-inch)",:icon_path => "#{path}/com.apple.powerbook-g4-12.png"},
         {:name => "PowerBook G4 (15-inch)",:icon_path => "#{path}/com.apple.powerbook-g4-15.png"},
         {:name => "PowerBook G4 (17-inch)",:icon_path => "#{path}/com.apple.powerbook-g4-17.png"},
         {:name => "PowerBook G4 Titanium",:icon_path => "#{path}/com.apple.powerbook-g4-titanium.png"},
         {:name => "PowerMac G4 Graphite",:icon_path => "#{path}/com.apple.powermac-g4-graphite.png"},
         {:name => "PowerMac G4 Quicksilver",:icon_path => "#{path}/com.apple.powermac-g4-quicksilver.png"},
         {:name => "PowerMac G5",:icon_path => "#{path}/com.apple.powermac-g5.png"},
         {:name => "VMWare Fusion",:icon_path => "#{path}/vmware_fusion.png"}]
    # Add the records
    a.each do |h|
      r = ComputerModel.find_or_create_by_name(h[:name])
      # Add an icon if there isn't one already
      if r.icon.nil?
        f = File.new(h[:icon_path])
        i = Icon.new
        i.photo = f
        unless i.save
          puts "#{h[:name]} computer model icon (#{h[:icon_path]}) failed to save: " + i.errors.inspect
        end
        r.icon = i
        f.close
      end
      unless r.save
        puts "#{h[:name]} computer model failed to save: " + r.errors.inspect
      end
    end
  end
  
  desc "Load default unit"
  task :unit, :name, :needs => :environment do |t, args|
    Rake::Task["bootstrap:environments"].invoke if Environment.count == 0
    name = args.name
    name ||= "Default"
    u = Unit.find_or_create_by_name(name)
    u.key = Unit.generate_key
    u.description = "Created by bootstrap"
    unless u.save
      puts "Default user failed to save: " + u.errors.inspect
    end
  end
  
  desc "Create default computer group"
  task :computer_group, :name, :needs => :environment do |t, args|
    # Makes we have a unit and an environment to assign
    Rake::Task["bootstrap:unit"].invoke if Unit.count == 0
    Rake::Task["bootstrap:environments"].invoke if Environment.count == 0
    name = args.name
    name ||= "Default"
    cg = ComputerGroup.find_or_create_by_name(name)
    cg.description = "Created by bootstrap"
    cg.unit = Unit.first
    cg.environment = Environment.find_by_name("Production")
    cg.environment = Environment.first if cg.environment.nil?
    unless cg.save
      puts "Default computer group failed to save: " + cg.errors.inspect
    end
  end
  
  desc "Load base user"
  task :user, :name, :needs => :environment do |t, args|
    # Make sure we have a unit to assign
    Rake::Task["bootstrap:unit"].invoke if Unit.count == 0
    username = args.name
    username ||= "default"
    u = User.find_or_create_by_username(username)
    u.email = "donotreply@gmail.com"
    u.password = "Password1"
    u.password_confirmation = "Password1"
    u.super_user = true
    u.save
    u.units = [Unit.first]
    unless u.save
      puts "Default user failed to save: " + u.errors.inspect
    end
  end
  
  desc "Load base environments"
  task :environments do |t, args|
    e = Environment.find_or_create_by_name("Staging")
    e.description = "Created by bootstrap"
    unless e.save
      puts "Staging environment failed to save: " + e.errors.inspect
    end
    e = Environment.find_or_create_by_name("Production")
    e.description = "Created by bootstrap"
    unless e.save
      puts "Production environment failed to save: " + e.errors.inspect
    end
  end
end

private
def tasks_in_namespace(ns)
  #grab all tasks in the supplied namespace
  tasks = Rake.application.tasks.select { |t| t.name =~ /^#{ns}:/ }
  #make sure we don't include the :all task
  tasks.reject! { |t| t.name =~ /:all/ }
end
