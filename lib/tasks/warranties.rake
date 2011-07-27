namespace :warranties do  
  desc "Update warranties for all available computers"
  task :update_all => :environment do
    computers = Computer.all.select{ |c| c.serial_number }
    computers.each do |comp|
      if comp.update_warranty
        puts "Successfully updated #{comp.name}'s warranty."
      else
        puts "Unsuccessfully updated #{comp.name}'s warranty."
      end
    end
  end
  
  desc "Destroys all warraties that have been saved"
  task :destroy_all => :environment do
    Warranty.destroy_all
  end
  
end