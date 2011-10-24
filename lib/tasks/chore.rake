namespace :chore do
  desc "Removes all unused (unreferenced) SystemProfile records."
  task :cleanup_system_profiles => :environment do
    results = SystemProfile.unused.map(&:destroy)
    total = results.count
    failed = results.delete_if {|e| e}.count
    puts "Destroyed #{total - failed} out of #{total} unused system profile records"
  end

  desc "Validates all models stored in the database"
  task :validate_models, [:validate_models] => :environment do |t, args|
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
  task :generate_shortnames, [:generate_shortnames] => :environment do
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
  
  desc "Send email to the primary user of a computer that have no checked-in to MuniServer for the past 30 days"
  task :inactive_computer_primary_user_notification, [:unit] => :environment do |t, args|
    unit = Unit.where(:name => args.unit).first if args.unit.present?
    if unit.present?
      puts "Found unit #{unit.name}"
      unit.computers.each do |computer|
        send_primary_user_notification(computer)
      end
    else
      puts "No unit found, default checking all computers"
      Computer.all.each do |computer|
        send_primary_user_notification(computer)
      end
    end
  end
end

private
def send_primary_user_notification(computer)
   if computer.last_report.present?
  # Find the computer that have not checked-in for the past 30 days
    if computer.last_report.created_at < 30.days.ago
      puts "Sending email to #{computer.name} primary user #{computer.primary_user}"
      # AdminMailer.inactive_primary_user_notification(computer).deliver
    end
  end
end 
