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
      puts "All Records are valid"
    else
      puts "Invalid Records"
      invalid.each do |inv|
        puts
        puts  "#{inv.inspect}"
        puts  "Errors: #{inv.errors}"
      end
    end
  end
  
  
  desc "If missing, create shortname attribute from name attribute for appropriate models"
  task :generate_shortnames, :needs => :environment do
    records = Unit.all + Computer.all + Bundle.all + ComputerGroup.all
    records.each do |record|
      if record.shortname.blank?
        record.shortname = record.conform_name_to_shortname
        print "Adding shortname to #{record}: #{record.shortname}..."
        if record.save
          puts "ok"
        else
          puts "error: #{record.errors.inspect}"
        end
      end
    end
  end
end