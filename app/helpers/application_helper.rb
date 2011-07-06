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
  def tabled_asm_select(parameters,table_class = "packagePicker",header_enabled = true)
    # If parameter is an active record model, get tas_params
    if parameters.class.superclass == ActiveRecord::Base
          parameters = parameters.tas_params
    end
    # Let us know if we're passing blank parameters (we shouldn't be)
    # parameters.each do |section|
    #       section.each do |key, val|
    #         if section[key].blank?
    #           puts "Error: parameters #{key} was blank!"
    #         end
    #       end
    #     end
    #render_table_asm_select(parameters, table_class, header_enabled)
    render :partial => "shared/table_multi_select", :locals => {:parameters => parameters, :table_class => table_class, :header_enabled => header_enabled} 
    
  end
  
  
  def render_table_asm_select(parameters,table_class,header_enabled)
    offset = 0
    parameters.to_s
    parameters.each_with_index do |section, i|
      if parameters[i+offset] == nil
        break
      else
        parameters[i+offset][:title].to_s
        offset += 1
      end

      
    end
    content_tag :table, :class => table_class do
      
    end     

  end  

  def display_package_version(pkgsinfo)
    unless Pkgsinfo.latest?(pkgsinfo)
      "(#{pkgsinfo.version})"
    end
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
  
  def super_user?
    current_user.super_user?
  end
  
  def current_unit
    @current_unit ||= Unit.where(:name => params[:unit]).first
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
  def units_menu
    units = current_user.units
    render :partial => "shared/units_menu", :locals => {:units => units, :current_unit => current_unit}
  end
  
  # Creates auto-complete text field for ASM select
  def autocomplete_asmselect(element_id, choices, default_value = '')
    element_id = element_id.gsub(" ","_").downcase
    render :partial => 'shared/autocomplete_asmselect', :locals => {:element_id => element_id, :autocomplete_id => element_id + "_autocomplete", :choices => choices, :default_value => default_value}
  end
  
  def field_lock_control(id)
    render :partial => 'shared/field_lock_control', :locals => {:id => id}
  end
  
  def current_link?(string)
    bool = false
    case string
    when "Computers"
      bool = (params[:controller] == "computers")
    when "Computer Groups"
      bool = (params[:controller] == "computer_groups")
    when "Bundles"
      bool = (params[:controller] == "groups")
    when "Packages"
      bool = (params[:controller] == "pkgsinfo")
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
  
  # Pass dom_id of element for rollover, and content for box
  def extra_info(dom_id,content,jq_event = 'mouseover')
    render :partial => 'shared/extra_info_box', :locals => {:dom_id => dom_id, :content => content, :jq_event => jq_event}
  end
  
  # Provides a question mark rollover with extra information
  def helpful_info(content,jq_event = 'click')
    dom_id = content[0,25].gsub(/[^[:alnum:]]/, '_') + "_" + rand(1001).to_s  
    code = image_tag('question_mark.png', :id => dom_id, :style => "vertical-align:middle;cursor:pointer")
    code += extra_info(dom_id,content,jq_event)
    code
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
  
  def unit_link(unit, controller)
    included_controllers = ["computers","packages","computer_groups","bundles","shared_packages","install_items"]
    controller = "computers" unless included_controllers.include?(controller)
    {:controller => controller, :action => :index, :unit => unit.to_param}
  end
end