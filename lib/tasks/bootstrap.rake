namespace :bootstrap do
  desc "Executing Munkiserver bootstrap tasks"
  task :all do
    tasks = tasks_in_namespace("bootstrap")
    Rake::Task["bootstrap:create_assets_directory"].invoke # do this first
    tasks.each do |task|
      Rake::Task[task].invoke
      # Had some failing tasks, give them a second to breathe
      sleep 1
    end
  end
  
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
    # Add machine model icons
    a = a + [{:name => "PowerMac4,4",:icon_path => "#{path}/com.apple.emac.png"},
             {:name => "PowerMac6,4",:icon_path => "#{path}/com.apple.emac.png"},
             {:name => "PowerBook2,1",:icon_path => "#{path}/com.apple.ibook-g4-12.png"},
             {:name => "PowerBook2,2",:icon_path => "#{path}/com.apple.ibook-g4-12.png"},
             {:name => "PowerBook4,1",:icon_path => "#{path}/com.apple.ibook-g4-12.png"},
             {:name => "PowerBook4,2",:icon_path => "#{path}/com.apple.ibook-g4-14.png"},
             {:name => "PowerBook4,3",:icon_path => "#{path}/com.apple.ibook-g4-14.png"},
             {:name => "PowerBook6,3",:icon_path => "#{path}/com.apple.ibook-g4-14.png"},
             {:name => "PowerBook6,5",:icon_path => "#{path}/com.apple.ibook-g4-14.png"},
             {:name => "PowerBook6,7",:icon_path => "#{path}/com.apple.ibook-g4-14.png"},
             {:name => "iMac7,1",:icon_path => "#{path}/com.apple.imac-aluminum-24.png"},
             {:name => "iMac8,1",:icon_path => "#{path}/com.apple.imac-aluminum-24.png"},
             {:name => "iMac9,1",:icon_path => "#{path}/com.apple.imac-aluminum-24.png"},
             {:name => "iMac,1",:icon_path => "#{path}/com.apple.imac-g4-15.png"},
             {:name => "PowerMac2,1",:icon_path => "#{path}/com.apple.imac-g4-15.png"},
             {:name => "PowerMac2,2",:icon_path => "#{path}/com.apple.imac-g4-15.png"},
             {:name => "PowerMac4,1",:icon_path => "#{path}/com.apple.imac-g4-15.png"},
             {:name => "PowerMac4,2",:icon_path => "#{path}/com.apple.imac-g4-15.png"},
             {:name => "PowerMac4,5",:icon_path => "#{path}/com.apple.imac-g4-17.png"},
             {:name => "PowerMac6,1",:icon_path => "#{path}/com.apple.imac-g4-17.png"},
             {:name => "PowerMac6,3",:icon_path => "#{path}/com.apple.imac-g4-20.png"},
             {:name => "PowerMac8,1",:icon_path => "#{path}/com.apple.imac-g5-17.png"},
             {:name => "PowerMac8,2",:icon_path => "#{path}/com.apple.imac-g5-20.png"},
             {:name => "PowerMac12,1",:icon_path => "#{path}/com.apple.imac-iSight-17.png"},
             {:name => "iMac5,2",:icon_path => "#{path}/com.apple.imac-iSight-17.png"},
             {:name => "iMac4,1",:icon_path => "#{path}/com.apple.imac-iSight-20.png"},
             {:name => "iMac5,1",:icon_path => "#{path}/com.apple.imac-iSight-20.png"},
             {:name => "iMac6,1",:icon_path => "#{path}/com.apple.imac-iSight-24.png"},
             {:name => "iMac10,1",:icon_path => "#{path}/com.apple.imac-unibody-27.png"},
             {:name => "iMac11,2",:icon_path => "#{path}/com.apple.imac-unibody-21.png"},
             {:name => "iMac11,1",:icon_path => "#{path}/com.apple.imac-unibody-27.png"},
             {:name => "iMac11,2",:icon_path => "#{path}/com.apple.imac-unibody-21.png"},
             {:name => "iMac12,1",:icon_path => "#{path}/com.apple.imac-unibody-27.png"},
             {:name => "iMac12,2",:icon_path => "#{path}/com.apple.imac-unibody-27.png"},
             {:name => "MacBook1,1",:icon_path => "#{path}/com.apple.macbook-white.png"},
             {:name => "MacBook2,1",:icon_path => "#{path}/com.apple.macbook-white.png"},
             {:name => "MacBook3,1",:icon_path => "#{path}/com.apple.macbook-white.png"},
             {:name => "MacBook4,1",:icon_path => "#{path}/com.apple.macbook-white.png"},
             {:name => "MacBook5,2",:icon_path => "#{path}/com.apple.macbook-white.png"},
             {:name => "MacBook6,1",:icon_path => "#{path}/com.apple.macbook-unibody-plastic.png"},
             {:name => "MacBook7,1",:icon_path => "#{path}/com.apple.macbook-unibody-plastic.png"},
             {:name => "MacBook5,1",:icon_path => "#{path}/com.apple.macbook-unibody.png"},
             {:name => "MacBookAir1,1",:icon_path => "#{path}/com.apple.macbookair.png"},
             {:name => "MacBookAir2,1",:icon_path => "#{path}/com.apple.macbookair.png"},
             {:name => "MacBookAir3,1",:icon_path => "#{path}/com.apple.macbookair.png"},
             {:name => "MacBookAir3,2",:icon_path => "#{path}/com.apple.macbookair.png"},
             {:name => "MacBookPro5,5",:icon_path => "#{path}/com.apple.macbookpro-13-unibody.png"},
             {:name => "MacBookPro7,1",:icon_path => "#{path}/com.apple.macbookpro-13-unibody.png"},
             {:name => "MacBookPro8,1",:icon_path => "#{path}/com.apple.macbookpro-13-unibody.png"},
             {:name => "MacBookPro5,1",:icon_path => "#{path}/com.apple.macbookpro-15-unibody.png"},
             {:name => "MacBookPro5,3",:icon_path => "#{path}/com.apple.macbookpro-15-unibody.png"},
             {:name => "MacBookPro5,4",:icon_path => "#{path}/com.apple.macbookpro-15-unibody.png"},
             {:name => "MacBookPro6,2",:icon_path => "#{path}/com.apple.macbookpro-15-unibody.png"},
             {:name => "MacBookPro8,2",:icon_path => "#{path}/com.apple.macbookpro-15-unibody.png"},
             {:name => "MacBookPro5,2",:icon_path => "#{path}/com.apple.macbookpro-17-unibody.png"},
             {:name => "MacBookPro6,1",:icon_path => "#{path}/com.apple.macbookpro-17-unibody.png"},
             {:name => "MacBookPro8,3",:icon_path => "#{path}/com.apple.macbookpro-17-unibody.png"},
             {:name => "MacBookPro1,1",:icon_path => "#{path}/com.apple.macbookpro-15.png"},
             {:name => "MacBookPro2,2",:icon_path => "#{path}/com.apple.macbookpro-15.png"},
             {:name => "MacBookPro3,1",:icon_path => "#{path}/com.apple.macbookpro-15.png"},
             {:name => "MacBookPro4,1",:icon_path => "#{path}/com.apple.macbookpro-15.png"},
             {:name => "MacBookPro1,2",:icon_path => "#{path}/com.apple.macbookpro-17.png"},
             {:name => "MacBookPro2,1",:icon_path => "#{path}/com.apple.macbookpro-17.png"},
             {:name => "Macmini4,1",:icon_path => "#{path}/com.apple.macmini-server.png"},
             {:name => "PowerMac10,1",:icon_path => "#{path}/com.apple.macmini.png"},
             {:name => "PowerMac10,2",:icon_path => "#{path}/com.apple.macmini.png"},
             {:name => "Macmini1,1",:icon_path => "#{path}/com.apple.macmini.png"},
             {:name => "Macmini2,2",:icon_path => "#{path}/com.apple.macmini.png"},
             {:name => "Macmini3,1",:icon_path => "#{path}/com.apple.macmini.png"},
             {:name => "MacPro1,1",:icon_path => "#{path}/com.apple.macpro.png"},
             {:name => "MacPro2,1",:icon_path => "#{path}/com.apple.macpro.png"},
             {:name => "MacPro3,1",:icon_path => "#{path}/com.apple.macpro.png"},
             {:name => "MacPro4,1",:icon_path => "#{path}/com.apple.macpro.png"},
             {:name => "MacPro5,1",:icon_path => "#{path}/com.apple.macpro.png"}]
    # Add the records
    count = 0
    a.each do |h|
      r = ComputerModel.where(:name => h[:name]).first
      r ||= ComputerModel.new(:name => h[:name])
      # Replace the icon with the one specified
      i = Icon.where(:photo_file_name => File.basename(h[:icon_path])).first
      if i.nil?
        f = File.new(h[:icon_path])
        i = Icon.new
        i.photo = f
        f.close
        puts "#{h[:name]} computer model icon (#{h[:icon_path]}) failed to save: " + i.errors.inspect unless i.save
      end
      r.icon = i
      unless r.save
        puts "#{h[:name]} computer model failed to save: " + r.errors.inspect
      end
      count += 1
    end
  end
  
  desc "Load default unit"
  task :unit, [:name] => :environment do |t, args|
    Rake::Task["bootstrap:environments"].invoke if Environment.count == 0
    name = args.name
    name ||= "Default"
    u = Unit.find_or_create_by_name(name)
    u.shortname = u.conform_name_to_shortname
    u.key = Unit.generate_key
    u.description = "Created by bootstrap"
    unless u.save
      puts "Default user failed to save: " + u.errors.inspect
    end
  end
  
  desc "Create default computer group"
  task :computer_group, [:name] => :environment do |t, args|
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
  
  desc "Create first user"
  task :user, [:name] => :environment do |t, args|
    if User.first.present?
      puts "First user (#{User.first.username}) already exists"
    else
      puts "Generating a new user"    
      # Make sure we have a unit to assign
      Rake::Task["bootstrap:unit"].invoke unless Unit.count
      username = args.name
      unless username
        print "Username: "
        username = STDIN.gets.chomp
      end
      u = User.new(:username => username)
      print "Email: "
      u.email = STDIN.gets.chomp
      print "Password: "
      u.password = STDIN.gets.chomp
      print "Confirm password: "
      u.password_confirmation = STDIN.gets.chomp
      u.super_user = true
      u.units << Unit.first
      unless u.save
        puts "Default user failed to save: " + u.errors.inspect
      end
    end
  end
  
  desc "create a new settings.yaml file optional arguments rake setup:create[hostname] default localhost:3000"
  task :settings, [:hostname] => :environment do |t, args|
    if File.exists?("config/settings.yaml")
      puts "settings.yaml file is already exists"
    else
      #if settings.yaml file doesn't exists
      hostname = args.hostame
      puts "Grenerating settings.yaml file, if blank default to \"localhost:3000\""
      print "Hostname: "
      hostname = STDIN.gets.chomp
      if hostname.empty?
        hostname = "localhost:3000"
      end
       h = {}
        File.open( "config/settings.yaml", "w" ) do |file|
         h[:action_mailer] = {:host => "#{hostname}" }
         file.write(h.to_yaml)
        end
    end
  end
  
  desc "Load base environments"
  task :environments do |t, args|
    #Build the staging environment
    e = Environment.find_or_create_by_name("Staging")
    e.description = "Created by bootstrap"
    unless e.save
      puts "Staging environment failed to save: " + e.errors.inspect
    end
    
    #Build the production environment
    e = Environment.find_or_create_by_name("Production")
    e.description = "Created by bootstrap"
    unless e.save
      puts "Production environment failed to save: " + e.errors.inspect
    end
  end
  
  desc "Generate preflight script"
  task :prelight_script do |t, args|
    # Build a preflight script dependant 
    
  end
  
  desc "Generate crontab jobs passing rails current environment"
  task :crontab => :environment do
    `whenever --update-crontab --set environment=#{Rails.env}`
  end
  
  desc "Create munkiserver_asset symlink as sibling of munkiserver directory"
  task :create_assets_directory => :environment do
    assets_dir = "#{Rails.root}/../munkiserver_assets"
    unless File.exist?(assets_dir)
      `mkdir #{assets_dir}`
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
