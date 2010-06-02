namespace :init do
  desc "Initialize models at deployment"
  task :models => :environment do
    print "Adding package categories..."
    `rake init:package_categories`
    puts "done"

    print "Adding computer models..."
    `rake init:computer_models`
    puts "done"
    
    print "Adding generic icon..."
    `rake init:generic_icon`
    puts "done"
  end
  
  desc "Add a generic icon to the Icon model"
  task :generic_icon => :environment do
    path = Rails.root.to_s + "/public/default_icons"
    i = Icon.new(:uploaded_data => LocalFile.new("#{path}/generic.png"))
    i.save
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
      i = Icon.new(:uploaded_data => LocalFile.new(h[:icon_path]))
      r.icon = i
      r.save
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
         {:name => "PowerMac G5",:icon_path => "#{path}/com.apple.powermac-g5.png"}]
    # Add the records
    a.each do |h|
      r = ComputerModel.find_or_create_by_name(h[:name])
      i = Icon.new(:uploaded_data => LocalFile.new(h[:icon_path]))
      r.icon = i
      r.save
    end
  end
end