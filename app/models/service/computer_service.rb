# A helper class that connects the controller to the model in a special way
# thus cleaning up the implementation of the controller quite a bit.
class ComputerService
  attr_accessor :computer, :attr

  # Creates a ComputerService object that does the extra params hash handling
  # duties (such as querying for PackageBranch records)
  # TO-DO Optimization: if the IDs were used to create association objects directly, it would save some work
  def initialize(computer, attributes)
    @computer = computer
    @attr = attributes
    
    # Retrieve PackageBranch records for all installs if edit_*installs is not nil
    # If no valid PackageBranch IDs are passed, an ActiveRecord::RecordNotFound
    # exception will be thrown and will cause the @attr[:*install] to be set to nil
    @attr[:installs] = PackageBranch.where(:id => @attr[:installs]).to_a if @attr[:installs] != nil
    @attr[:uninstalls] = PackageBranch.where(:id => @attr[:uninstalls]).to_a if @attr[:uninstalls] != nil
    @attr[:user_installs] = PackageBranch.where(:id => @attr[:user_installs]).to_a if @attr[:user_installs] != nil
    @attr[:user_uninstalls] = PackageBranch.where(:id => @attr[:user_uninstalls]).to_a if @attr[:user_uninstalls] != nil
    # Retrieve bundle records in the exact way as done with the *installs
    @attr[:bundles] = Bundle.where(:id => @attr[:bundles]).to_a if @attr[:bundles] != nil
  end
  
  # Perform a save on the @computer object (after assigning all the *installs)
  def save
    @computer.update_attributes(@attr)
  end
  
  # Takes some options (importantly, a plist file) a creates computer objects
  # Objects are not yet saved.  So, keep that in mind, eh?
  # Returns nil if plist or computer group had issues.  Returns empty array
  # if the plist had no items
  def self.import(params, unit)
    # Flag if error occurs
    error_occurred = false
    # Stores created computer objects
    computers = nil
    # Shorten params
    plist = params[:plist]
    computer_group_id = params[:computer_group_id].to_i
    environment_id = params[:environment_id].to_i
    
    
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
      cg ||= ComputerGroup.new({:name => h["listName"], :unit_id => unit.id})
      cg.save if cg.new_record?
    elsif computer_group_id > 0
      cg = ComputerGroup.find_by_id(computer_group_id)
    end
  
    # Make sure we have a computer group and a environment
    if cg.nil?
      error_occurred = true
    end

    unless error_occurred
      computers = []
    
      h["items"].each do |computer_info|
        # TO-DO create a Computer.new_from_template that returns a non-saved 
        # new object that has some set of default values associated with it
        # This method should behave the exact same way as new except that if
        # something isn't set (like computer model) that is set in the template
        # then the template setting is applied
        c = Computer.new({:mac_address => computer_info["hardwareAddress"],
                          :name => computer_info["hostname"],
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
  def self.collect(params,unit)
    # Grab the computers belonging to a specific unit
    computers = Computer.unit(unit)
    
    # Modify the query for sorting
    unless params[:order].blank?
      col = nil
      # Add valid columns as needed (this protects
      # against injection attacks or errors)
      case params[:col]
        when "mac_address" then col = "mac_address"
        else col = "hostname"
      end
      computers = computers.order(col + " " + params[:order])
    end
    
    # Modify for a specific hostname
    unless params[:name].blank?
      computers = computers.where(["name LIKE ?","%#{params[:name]}%"])
    end
    
    # Add pagination using will_paginate gem
    computers = computers.paginate(:page => params[:page], :per_page => 10)

    # Return our results
    computers
  end
end