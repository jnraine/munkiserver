# A helper class that connects the controller to the model in a special way
# thus cleaning up the implementation of the controller quite a bit.
class ComputerService
  attr_accessor :computer, :attr
  
  # Takes some options (importantly, a plist file) a creates computer objects
  # Objects are not yet saved.  So, keep that in mind, eh?
  # Returns nil if plist or computer group had issues.  Returns empty array
  # if the plist had no items
  def self.import(params, unit)
    # Flag if error occurs
    error_occurred = false
    plist = params[:plist]
    computer_group_id = params[:computer_group_id].to_i
    
    h = Plist.parse_xml(plist.read) if plist.respond_to?(:read)
    
    # Check for some bad parameters
    # => plist wasn't a valid plist
    # => plist items element wasn't an array
    if h.nil? or h["items"].class != Array
      error_occurred = true
    end
    
    # Sort out what computer group we'll be adding the objects to
    # If a computer group ID of zero is passed, it means, pick a group
    # in a smart way.
    cg = nil
    if computer_group_id == 0
      cg = ComputerGroup.unit(unit).find_by_name(h["listName"])
      cg ||= ComputerGroup.new({:name => h["listName"], :unit_id => unit.id, :environment_id => Environment.find_by_name("Production").id})
      cg.save if cg.new_record?
    elsif computer_group_id > 0
      cg = ComputerGroup.find_by_id(computer_group_id)
    end
  
    # Make sure we have a computer group and a environment
    if cg.nil?
      error_occurred = true
    end

    # Create and collect new computer records
    computers = nil
    unless error_occurred
      environment_id = cg.environment.id
      computers = []
    
      h["items"].each do |computer_info|
        # TO-DO create a Computer.new_from_template that returns a non-saved 
        # new object that has some set of default values associated with it
        # This method should behave the exact same way as new except that if
        # something isn't set (like computer model) that is set in the template
        # then the template setting is applied
        c = Computer.new({:mac_address => computer_info["hardwareAddress"],
                          :name => computer_info["name"],
                          :hostname => computer_info["hostname"],
                          :unit_id => unit.id,
                          :environment_id => environment_id})
        c.computer_group = cg
        c.computer_model = ComputerModel.default
        computers << c
      end
    end
    
    computers
  end
  
  # Returns a collection based on the params passed as well as a unit.
  # Intended to encapsulate the typical query done for the index action.
  def self.collect(params, unit, env)
    # Grab the computers belonging to a specific unit
    # Set environment    
    computers = Computer.unit_and_environment(unit,env)
    
    # Modify the query for sorting
    unless params[:order].blank?
      col = nil
      # Add valid columns as needed (this protects
      # against injection attacks or errors)
      case params[:col]
        when "mac_address" then col = "mac_address"
        when "last_report" then col = "last_report"
        else col = "name"
      end
      computers = computers.order(col + " " + params[:order])
    end
    
    # Modify for a specific hostname
    unless params[:name].blank?
      computers = computers.where(["name LIKE ?","%#{params[:name]}%"])
    end
    
    # Add pagination using will_paginate gem
    per_page = params[:per_page]
    per_page ||= Computer.per_page
    computers = computers.paginate(:page => params[:page], :per_page => per_page)

    # Return our results
    computers
  end
end