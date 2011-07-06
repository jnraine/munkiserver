# A helper class that connects the controller to the model in a special way
# thus cleaning up the implementation of the controller quite a bit.
class ManifestService
  attr_accessor :manifest, :attr

  # Creates a BundleService object that does the extra params hash handling
  # duties (such as querying for PackageBranch records)
  # TO-DO Optimization: if the IDs were used to create association objects directly, it would save some work
  def initialize(manifest, attributes)
    @manifest = manifest
    @attr = attributes
    
    # Retrieve PackageBranch records for all installs if edit_*installs is not nil
    # If no valid PackageBranch IDs are passed, an ActiveRecord::RecordNotFound
    # exception will be thrown and will cause the @attr[:*install] to be set to nil
    @attr[:installs] = PackageBranch.where(:id => @attr[:installs]).to_a if @attr[:installs] != nil
    @attr[:uninstalls] = PackageBranch.where(:id => @attr[:uninstalls]).to_a if @attr[:uninstalls] != nil
    @attr[:user_installs] = PackageBranch.where(:id => @attr[:user_installs]).to_a if @attr[:user_installs] != nil
    @attr[:user_uninstalls] = PackageBranch.where(:id => @attr[:user_uninstalls]).to_a if @attr[:user_uninstalls] != nil
    @attr[:optional_installs] = PackageBranch.where(:id => @attr[:optional_installs]).to_a if @attr[:optional_installs] != nil
    # Retrieve bundle records in the exact way as done with the *installs
    @attr[:bundles] = Bundle.where(:id => @attr[:bundles]).to_a if @attr[:bundles] != nil
  end
  
  # Perform a save on the @manifest object (after assigning all the *installs)
  def save
    @manifest.update_attributes(@attr)
  end
  
  # Takes some options (importantly, a plist file) a creates manifest objects
  # Objects are not yet saved.  So, keep that in mind, eh?
  # Returns nil if plist or manifest group had issues.  Returns empty array
  # if the plist had no items
  def self.import(params, unit)
    # Flag if error occurs
    error_occurred = false
    # Stores created manifest objects
    manifests = nil
    # Shorten params
    plist = params[:plist]
    manifest_group_id = params[:manifest_group_id].to_i
    environment_id = params[:environment_id].to_i
    
    
    h = Plist.parse_xml(plist.read) if plist.respond_to?(:read)
    
    # Check for some bad parameters
    # => plist wasn't a valid plist
    # => plist items element wasn't an array
    if h.nil? or h["items"].class != Array
      error_occurred = true
    end
    
    # Sort out what manifest group we'll be adding the objects to
    # If a manifest group ID of zero is passed, it means, pick a group
    # in a smart way.
    cg = nil
    if manifest_group_id == 0
      cg = manifestGroup.unit(unit).find_by_name(h["listName"])
      cg ||= manifestGroup.new({:name => h["listName"], :unit_id => unit.id})
      cg.save if cg.new_record?
    elsif manifest_group_id > 0
      cg = manifestGroup.find_by_id(manifest_group_id)
    end
  
    # Make sure we have a manifest group and a environment
    if cg.nil?
      error_occurred = true
    end

    unless error_occurred
      manifests = []
    
      h["items"].each do |manifest_info|
        # TO-DO create a manifest.new_from_template that returns a non-saved 
        # new object that has some set of default values associated with it
        # This method should behave the exact same way as new except that if
        # something isn't set (like manifest model) that is set in the template
        # then the template setting is applied
        c = manifest.new({:mac_address => manifest_info["hardwareAddress"],
                          :name => manifest_info["hostname"],
                          :unit_id => unit.id,
                          :environment_id => environment_id})
        c.manifest_group = cg
        c.manifest_model = manifestModel.first
        manifests << c
      end
    end
    
    manifests
  end
  
  # Returns a collection based on the params passed as well as a unit.
  # Intended to encapsulate the typical query done for the index action.
  def self.collect(params,unit)
    # Grab the manifests belonging to a specific unit
    manifests = manifest.unit(unit)
    
    # Modify the query for sorting
    unless params[:order].blank?
      col = nil
      # Add valid columns as needed (this protects
      # against injection attacks or errors)
      case params[:col]
        when "mac_address" then col = "mac_address"
        else col = "hostname"
      end
      manifests = manifests.order(col + " " + params[:order])
    end
    
    # Modify for a specific hostname
    unless params[:name].blank?
      manifests = manifests.where(["name LIKE ?","%#{params[:name]}%"])
    end
    
    # Add pagination using will_paginate gem
    manifests = manifests.paginate(:page => params[:page], :per_page => 10)

    # Return our results
    manifests
  end
end