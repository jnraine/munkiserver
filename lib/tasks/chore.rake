namespace :chore do
  desc "Removes all unused (unreferenced) SystemProfile records."
  task :cleanup_system_profiles, :needs => :environment do
    results = SystemProfile.unused.map(&:destroy)
    total = results.count
    failed = results.delete_if {|e| e}.count
    puts "Destroyed #{total - failed} out of #{total} unused system profile records"
  end

  desc "Validates all models stored in the database, optional 'no_color' argument to suppress colorizing output."
  task :validate_models, :no_color, :needs => :environment do |t, args|
    # Check for color
    DONT_COLORIZE = args.colorize == "no_color"
    
    
    #Force load all models
    Dir[Rails.root + 'app/models/**/*.rb'].each do |path|
      require path
    end
    
    # Find all subclasses of ActiveRecord::Base and validate
    subclasses = ActiveRecord::Base.send(:subclasses)
    invalid = []
    subclasses.each do |klass|
      puts "\nValidating #{klass.name.pluralize}"
      klass.all.each do |instance|
        if instance.valid?
          green_puts "    #{instance.inspect}"
        else
          red_puts "    #{instance.inspect}"
          invalid << instance unless instance.valid?
        end
      end
    end
    
    #Print results
    puts "\n-------------------------------------------------------------------\n\n"
    if invalid.empty?
      puts "All Records are vailid\n\n"
    else
      puts "Listing Invalid Records\n\n"
      invalid.each do |inv|
        red_puts  "  #{inv.inspect}"
        puts      "      Errors: #{inv.errors}\n\n"
      end
    end
  end
end

# Helper Methods
def colorize(color, text, mode = 'fg')
  if DONT_COLORIZE
    text
  else
    "\x1b[38;5;#{color}m#{text}#{nocolor("\n")}"
  end
end

def nocolor(text)
  if DONT_COLORIZE
    text
  else
    "\x1b[0m#{text}"
  end
end

def red_puts(string)
  puts colorize(9, string)
end

def green_puts(string)
  puts colorize(10, string)
end