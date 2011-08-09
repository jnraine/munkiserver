namespace :chore do
  desc "Removes all unused (unreferenced) SystemProfile records."
  task :cleanup_system_profiles, :needs => :environment do
    results = SystemProfile.unused.map(&:destroy)
    total = results.count
    failed = results.delete_if {|e| e}.count
    puts "Destroyed #{total - failed} out of #{total} unused system profile records"
  end

  desc "Validates all models stored in the database"
  task :validate_models, :needs => :environment do |t, args|
    #Force load all models
    Dir[Rails.root + 'app/models/**/*.rb'].each do |path|
      require path
    end
    
    # Find all subclasses of ActiveRecord::Base and validate
    subclasses = ActiveRecord::Base.send(:subclasses)
    invalid = []
    subclasses.each do |klass|
      puts "Validating #{klass.name.pluralize}"
      klass.all.each do |instance|
      invalid << instance unless instance.valid?
      end
    end
    
    #Print results
    puts "\n-------------------------------------------------------------------\n\n"
    if invalid.empty?
      puts "All Records are vailid"
    else
      puts "Invalid Records"
      invalid.each do |inv|
        puts
        puts  "#{inv.inspect}"
        puts  "Errors: #{inv.errors}"
      end
    end
  end
  
  
  desc "Create shortname attribute based off existing name's from models"
  task :generate_short_names, :needs => :environment do
    units = Unit.all
    computers = Computer.all
    bundles = Bundle.all
    computer_groups = ComputerGroup.all
    
    units.each do |unit|
      unit.shortname = unit.name.downcase.gsub(/[^a-z0-9]+/, '-')
      puts "Changing unit name \"#{unit.name}\" to #{unit.shortname}"
      unit.save
    end
    computers.each do |computer|
      computer.shortname = computer.name.downcase.gsub(/[^a-z0-9]+/, '-')
      puts "Changing computer name \"#{computer.name}\" to #{computer.shortname}"
      computer.save
    end
    bundles.each do |bundle|
      bundle.shortname = bundle.name.downcase.gsub(/[^a-z0-9]+/, '-')
      puts "Changing bundle name \"#{bundle.name}\" to #{bundle.shortname}"
      bundle.save
    end
    computer_groups.each do |computer_group|
      computer_group.shortname = computer_group.name.downcase.gsub(/[^a-z0-9]+/, '-')
      puts "Changing computer group name \"#{computer_group.name}\" to #{computer_group.shortname}"
      computer_group.save
    end
  end
end