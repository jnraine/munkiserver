# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  # Makes from_yaml method available to views / helpers (markup generators)
  def from_yaml(string,return_type = "default")
    # Use method added to ActiveRecord by ActiveRecordHelpers plugin
    ActiveRecord::Base.from_yaml(string,return_type)
  end
  
  # Outputs code for pkg list
  # Replaces html_package_list and build_html_package_list_item method
  def pkg_list(item_list,target = nil)
    empty_list_message = "<p><em>No packages assigned</em></p>"
    if item_list.empty?
      empty_list_message.html_safe
    else
      render :partial => "shared/pkg_list", :locals => {:item_list => item_list, :target => target}
    end
  end
  
  # Outputs code for group list
  def bundle_list(bundle_list,target = nil)
    empty_list_message = "<p><em>No bundles assigned</em></p>"
    if bundle_list.empty?
      empty_list_message.html_safe
    else
      render :partial => "shared/bundle_list", :locals => {:bundle_list => bundle_list, :target => target}
    end
  end
  
  def inventory(model_obj,target = nil)
    render :partial => "shared/inventory", :locals => {:model_obj => model_obj, :target => target}
  end
  
  # Pass an array of group names.  Pushes installed package names into second argument and uninstalled package names into third argument.  Calls itself for groups of passed groups names (checks fourth argument for already visited group names)
  def get_group_pkg_names(group_names,installed_pkg_names,uninstalled_pkg_names,visited_groups = [])
    group_names.each do |group_name|
      group = Group.first(:conditions => "name = '#{group_name}'")
      unless group.nil?
        installed_pkg_names = installed_pkg_names | from_yaml(group.managed_installs,"array")
        uninstalled_pkg_names = uninstalled_pkg_names | from_yaml(group.managed_uninstalls,"array")
      end
      
      # Unless group is not a member of any groups that haven't been visited, get nested group pkgsinfo
      filtered_groups = from_yaml(group.groups,"array") - visited_groups
      visited_groups = filtered_groups | visited_groups
      unless filtered_groups.empty?
        nested = get_group_pkg_names(from_yaml(group.groups,"array"),installed_pkg_names,uninstalled_pkg_names,visited_groups)
        installed_pkg_names = installed_pkg_names | nested['installed_pkg_names']
        uninstalled_pkg_names = uninstalled_pkg_names | nested['uninstalled_pkg_names']
      end
    end
    {"installed_pkg_names" => installed_pkg_names - [nil], "uninstalled_pkg_names" => uninstalled_pkg_names - [nil]} # Sometimes you get a nil in the array...this removes it.  I'm not sure why it is there.
  end
  
  # Creates a multiple select based on passed params
  # Parameters is filled with hashes with the following keys:
  # title, model_name, attribute_name, select_title, options
  def tabled_asm_select(parameters,table_class = nil,header_enabled = nil,environment_id = nil)
    # If parameter is an active record model, get tas_params
    if parameters.class.superclass == ActiveRecord::Base
      parameters = parameters.tas_params(environment_id)
    end
    
    # Ensure sane default values
    table_class ||= "packagePicker"
    header_enabled ||= true
    
    render :partial => "shared/table_multi_select", :locals => {:parameters => parameters, :table_class => table_class, :header_enabled => header_enabled} 
  end
  
  def record_count(model_objs,word = "record")
    if model_objs.empty?
      content_tag(:em, "displaying 0 of " + pluralize(0,word))
    else
      if model_objs.class == WillPaginate::Collection
        # If results are paginated
        per_page = model_objs.per_page
        records = model_objs.length
        page = model_objs.current_page
        total = model_objs.total_entries
        from = page == 1 ? 1 : ((page - 1) * per_page) + 1
        to = (from + records) - 1
      else
        # If results are normal
        total = model_objs.length
        from = 1
        to = total
      end
    
      range = "#{from}-#{to}"
      content_tag(:em,"displaying #{range} of " + pluralize(total,word))
    end
  end
  
  # Get current environment based on session[:environment_id] or value of 
  # Environment.default_view.  Change environment by passing param[:eid] to 
  def current_environment
    # Change environment if necessary
    session[:environment_id] = params[:eid] if params[:eid].present?    
    @current_environment = Environment.where(:id => session[:environment_id]).first
    @current_environment ||= Environment.default_view
  end
  
  def current_unit
    @current_unit ||= Unit.where(:shortname => params[:unit_shortname]).first
  end
  
  def current_user
    @current_user ||= User.find_by_username(session[:username])
  end
  
  def logged_in?
    current_user.present?
  end
    
  # Get current environment based on session[:environment_id] or value of 
  # Environment.default_view.  Change environment by passing param[:eid] to 
  def current_environment
    # Change environment if necessary
    session[:environment_id] = params[:eid] if params[:eid].present?    
    @current_environment = Environment.where(:id => session[:environment_id]).first
    @current_environment ||= Environment.default_view
  end
  
  def mine?(object)
    object.unit_id == current_unit_id
  end
  
  # Build units menu for currently logged in user
  def unit_menu
    units = current_user.units
    render :partial => "shared/unit_menu", :locals => {:units => units, :current_unit => current_unit}
  end
  
  # Creates auto-complete text field for ASM select
  def autocomplete_asmselect(element_id, choices, default_value = '')
    element_id = element_id.gsub(" ","_").downcase
    render :partial => 'shared/autocomplete_asmselect', :locals => {:element_id => element_id, :autocomplete_id => element_id + "_autocomplete", :choices => choices, :default_value => default_value}
  end
  
  def field_lock_control(id, locked = true)
    lock_state = locked ? "locked" : "unlocked"
    render :partial => 'shared/field_lock_control', :locals => {:id => id, :lock_state => lock_state}
  end
  
  def current_link?(string)
    bool = false
    case string
    when "Computers"
      bool = (params[:controller] == "computers")
    when "Computer Groups"
      bool = (params[:controller] == "computer_groups")
    when "User Groups"
      bool = (params[:controller] == "user_groups")
    when "Bundles"
      bool = (params[:controller] == "bundles")
    when "Packages"
      bool = (params[:controller] == "packages")
    end
    bool
  end
  
  # Takes int of bytes, returns humanized file size with unit
  def humanize_bytes(bytes)
    humanized_string = ''
    bytes = bytes.to_i
    kilobytes = bytes / 1024
    humanize_kilobytes(kilobytes)
  end
  
  # Takes int of bytes, returns humanized file size with unit
  def humanize_kilobytes(kilobytes)
    humanized_string = ''
    kilobytes = kilobytes.to_i
    if kilobytes > 1048576
      humanized_string = format("%.2f GB",kilobytes / 1048576.0)
    elsif kilobytes > 1024
      humanized_string = format("%.2f MB",kilobytes / 1024.0)
    else
      humanized_string = format("%.0f KB",kilobytes)
    end
    humanized_string
  end
  
  # Apply a "subtle value" to an object attribute (or pass static value)
  def subtle_value(model_obj,attribute,value = nil)
    if model_obj.class == String
      model_table = model_obj
    else
      model_table = model_obj.class.to_s.downcase
    end
    attribute = attribute.to_s
    dom_id = "#{model_table}_#{attribute}"
    value ||= attribute.humanize
    subtle_value_tag(dom_id,value)
  end

  # Apply a "subtle value" to a form element with passed ID and value
  def subtle_value_tag(dom_id,value)
    "<script type='text/javascript'>\n\tjQuery('##{dom_id}').subtle_value('#{value}');\n</script>\n".html_safe
  end
  
  # Provides a question mark rollover with extra information
  def helpful_info(content)
    render :partial => 'shared/helpful_info', :locals => {:content => content}
  end
  
  # Creates a set of tags for a checkbox: the checkbox, a label (with passed string), a hidden tag (to nullify value)
  def check_box_tag_set(name,label,value)
    value ||= "0"
    label = " #{label}"
    dom_id = name.gsub(/\[|\]| /,'_').gsub(/__|___/,'_').sub(/_$/,'')
    code = hidden_field_tag(name,'0', :id => dom_id + "_hidden" )
    code += check_box_tag(name,"1", value.to_bool)
    code += label_tag(dom_id,label)
    code
  end
  
  # Creates nicely formatted checkbox section from a hash
  def hash_checkboxes(h, options = {})
    defaults = {:title => "",:name => ""}
    options = defaults.merge(options)
    
    render "shared/hash_checkboxes", :locals => {:options => options, :h => h}
  end
  
  # Should be refactored to be more efficient
  def unit_link(unit, controller)
    raise ArgumentError.new("Unit passed to unit_link method was nil") if unit.nil?
    known = known_controllers
    controller = known.keys.first unless known.keys.include?(controller)
    authorized = false
    # Try to authorize for a specific controller ahead of time
    while not authorized and known.present?
      if can? :read, known.delete(controller).new_for_can(unit)
        authorized = true
      else
        controller = known.keys.first
      end
    end
    raise RuntimeError.new("#{current_user} does is not authorized to any read actions within the known controllers!") if not authorized
    {:controller => controller, :action => :index, :unit_shortname => unit.to_param}
  end
  
  # 
  # A hash of controller names and their corresponding model constants.  Using OrderedHash to maintain Ruby 1.8 support
  # 
  def known_controllers
    h = ActiveSupport::OrderedHash.new
    h["computers"] = Computer
    h["packages"] = Package
    h["computer_groups"] = ComputerGroup
    h["shared_packages"] = Package
    h["user_groups"] = UserGroup
    h["permissions"] = Permission
    h
  end
  
  # Return a macupdate.com URL for the given package
  def macupdate_url(package)
     VersionTracker::MAC_UPDATE_PACKAGE_URL + package.package_branch.version_tracker.web_id.to_s
  end
  
  def principal_list_item(principal, opts={})
    render :partial => 'shared/principal_list_item', :locals => {:principal => principal, :disabled => opts[:disabled]}
  end
end