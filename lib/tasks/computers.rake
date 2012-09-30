namespace :computers do
  task :add, [:name, :hostname, :mac_address, :unit, :environment, :group] => [:environment] do |t, args|
    u = Unit.find_by_name(args[:unit])
    e = Environment.find_by_name(args[:environment])
    g = ComputerGroup.where(:environment_id => e, :unit_id => u, :name => args[:group]).first
    Computer.create(name: args[:name], hostname: args[:hostname], mac_address: args[:mac_address], unit: u, environment: e, computer_group: g) 
    puts "Added #{args}"
  end
  task :delete, [:hostname, :mac_address] => [:environment] do |t, args|
    unless Computer.find_by_hostname(args[:hostname]).nil?
      Computer.find_by_hostname(args[:hostname]).destroy
    end
    unless Computer.find_by_mac_address(args[:mac]).nil?
      Computer.find_by_mac_address(args[:mac]).destroy
    end
    puts "Destroyed #{args}"
  end
end
