# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  # Commented...if there is no one using this, it will be removed.
  # Pass a plist file parse into hash.
  # def self.parsePlist(plist)
  #   require "plist"
  #   xml_string = plist.read
  #   plistHash = Plist.parse_xml(xml_string)
  # end
  
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
    
    htmlcode = "<table class='#{table_class}'>\n"
    
    # table header
    if header_enabled
      htmlcode += "\t<thead>\n"
      htmlcode += "\t\t<tr>\n"
      parameters.each do |section|
        htmlcode += "\t\t\t<th>#{section[:title]} "
        htmlcode += helpful_info(section[:helpful_string]) unless section[:helpful_string].blank?
        htmlcode +="</th>\n"
      end
      htmlcode += "\t\t</tr>\n"
      htmlcode += "\t</thead>\n"
    end
    
    htmlcode += "\t<tr>\n"
    
    parameters.each do |section|
      htmlcode += "\t\t<td>\n"
      htmlcode += hidden_field_tag("#{section[:model_name]}[#{section[:attribute_name]}][]",'')
      htmlcode += select_tag("#{section[:model_name]}[#{section[:attribute_name]}]", options_for_select(section[:options],section[:selected_options]), :multiple => true, :title => section[:select_title])
      #htmlcode += text_field_with_auto_complete(:quickly, section['title'].to_sym, { :size => 20, :class => "quickly_complete_field" }, { :url => formatted_pkgsinfo_index_path(:js), :method => :get, :with => "'search=' + element.value" })
      htmlcode += autocomplete_asmselect(section[:title],section[:options].collect { |el| el[0] },"type a name...")
      htmlcode += "\t\t</td>\n"
    end
    htmlcode += "\t</tr>\n"
    htmlcode += "</table>\n"
    htmlcode.html_safe
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
  
  # Checks if currently logged in user is a super user
  def super_user?
    current_user.super_user?
  end

  def logged_in?
    current_user != nil
  end

  def current_user
    # User.find_by_username(session[:username])
    @current_user ||= User.find_by_username("jraine")
  end
  
  def unit_set?
    current_unit_id != nil
  end
  
  def current_unit_id
    session[:unit_id]
  end
  
  def current_unit
    @unit_id ||= Unit.find(current_unit_id)
  end
  
  def mine?(object)
    object.unit_id == current_unit_id
  end
  
  # Build units menu for currently logged in user
  def units_menu
    unless current_unit.nil?
      units = current_user.units
      render :partial => "shared/units_menu", :locals => {:units => units, :current_unit => current_unit}
    end
  end
  
  # Creates auto-complete text field for ASM select
  def autocomplete_asmselect(element_id, choices, default_value = '')
    element_id = element_id.gsub(" ","_").downcase
    render :partial => 'shared/autocomplete_asmselect', :locals => {:element_id => element_id, :autocomplete_id => element_id + "_autocomplete", :choices => choices, :default_value => default_value}
  end
  
  def field_lock_control(id)
      link_to('unlock', '#', :onClick => "toggleDisabledTextField('#{id}');return false;", :id => "#{id}_control")
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
end
