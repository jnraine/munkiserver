namespace :chore do
  desc "Removes MissingManifests created after X days ago (defaults to 30 days)"  
  task :cleanup_missing_manifests, [:days_kept] => [:environment] do |t, args|
    args.with_defaults(:days_kept => 30)
    results = MissingManifest.where("created_at < :date", :date => (Date.today - args[:days_kept].to_i.days)).destroy_all
    puts "Destroyed #{results.count} missing manifests"
  end
  
  desc "Removes ManagedInstallReports created after X days ago (defaults to 30 days)"
  task :cleanup_old_managed_install_reports, [:days_kept] => [:environment] do |t, args|
    args.with_defaults(:days_kept => 30)
    results = ManagedInstallReport.where("created_at < :date", :date => (Date.today - args[:days_kept].to_i.days)).destroy_all
    puts "Destroyed #{results.count} managed install reports"
  end
  
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
  
  desc "Destroy item model records that reference nil packages"
  task :destroy_stale_item_records => :environment do
    InstallItem.destroy_stale_records
    BundleItem.destroy_stale_records
    ManagedUpdateItem.destroy_stale_records
    OptionalInstallItem.destroy_stale_records
    RequireItem.destroy_stale_records
    UninstallItem.destroy_stale_records
    UpdateForItem.destroy_stale_records
  end
end