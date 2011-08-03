module PackagesHelper
  # Pass an array of builtin icon hash (name => "name", filename => "name.png")
  def icon_picker(array,current_icon)
    input_name = "builtin_icon"
    builtin = false
    htmlcode = ""
    array.each { |icon|
      htmlcode += "<p class ='builtin_icons'>"
      htmlcode += image_tag("pkgicons/#{icon['filename']}", :height => "30px")
      if icon['filename'] == current_icon
        htmlcode += radio_button_tag input_name, icon['filename'], :selected => true
        builtin = true
      else
        htmlcode += radio_button_tag input_name, icon['filename']
      end
      htmlcode += label_tag "#{input_name}_#{icon['filename'].gsub('.','')}", icon['name']
      htmlcode += "</p>"
    }
    htmlcode += "<p class ='builtin_icons'>"
    htmlcode += image_tag("pkgicons/#{current_icon}", :height => "30px")
    unless builtin
      htmlcode += radio_button_tag input_name, "custom", :selected => true
    else
        htmlcode += radio_button_tag input_name, "custom"    
    end
    htmlcode += label_tag "#{input_name}_custom", "Custom "
    htmlcode += file_field_tag 'icon'
    htmlcode += "</p>"
  end

	def package_header(package, show = nil)
	  packages = Package.same_unit(package).where(:package_branch_id => package.package_branch_id).order("version ASC")
	  show ||= false 
    render :partial => 'record_header', :locals => {
                              														:title => package.display_name,
                              														:img => package.icon,
                              														:soft_info => package.name,
                              														:bold_info => package.version,
                              														:packages => packages,
                              														:show => show }
	end
	
	def recent_packages
	 pkgs = Package.recent(current_unit)
	 shared_pkgs = Package.shared_recent(current_unit)
	 render :partial => 'recent', :locals  => { :pkgs => pkgs, :shared_pkgs => shared_pkgs }
	end
	
	def package_table(packages)
	  # Split different categories into different arrays
	  categorized = {}
	  packages.each do |package|
	    category_name = package.package_category.name
      categorized[category_name] ||= []
      categorized[category_name] << package
    end
    
    output = ""
	  # Render header and table for each category
	  categorized.each_pair do |category_name, packages|
	    output += render :partial => 'packages_of_category_table', :locals => {:category_name => category_name, :packages => packages}  
    end
    output.html_safe
  end
  
  # Check version tracker for package updates, display available updates
  def available_updates
    # Grab all package branches in for this unit
    pbs = PackageBranch.unit(current_unit)
    # Remove branches if there isn't a new version
    pbs.delete_if {|pb| !pb.new_version?(current_unit) }.compact
    render :partial => 'available_updates', :locals => {:package_branches => pbs}
  end
  
  
  def render_pkgsinfo_category_icon(object, height = "30px")
    pkgsinfo_category = object.pkgsinfo_category
    pkgsinfo_category ||= object
    concat(image_tag("#{PKGSINFO_ICON_REL_PATH}/#{pkgsinfo_category.icon}", :height => height, :style => "vertical-align:middle;"))
  end
  
  def render_pkgsinfo_icon(object, height = "30px")
    concat(image_tag("#{PKGSINFO_ICON_REL_PATH}/#{object.icon}", :height => height, :style => "vertical-align:middle;"))
  end
  
  def render_gui_installer_choices(choices_hash)
    sorted_choices = Pkgsinfo.sort_choices(choices_hash)
    concat(render :partial => 'gui_installer_choices', :locals => {:sorted_choices => sorted_choices})
  end
  
  def render_pkgsinfo_plist_errors
    all_pkgsinfos = Pkgsinfo.all
    invalid_plists = []
    # Collect all errors
    all_pkgsinfos.each do |pkgsinfo|
      unless pkgsinfo.plist_valid?
        invalid_plists << {'errors' => pkgsinfo.plist_validation_results, 'pkgsinfo' => pkgsinfo}
      end
    end
    concat(render :partial => 'pkgsinfo_plist_errors', :locals => {:invalid_plists => invalid_plists })
  end
  
  # Return true if there exists packages in other unit that are shared and has higher version
  # add logic to compare if version tracker has high version or the import package has higher version
  # return true if the shared package is higher or equal to the version tracker version else return the version tracker version
  def has_shared?(package)
    if import_package(package).present?
      return true if (import_package(package).unit_id != current_unit.id)
    else
      return false
    end
  end
  
  # Return true if there is package available to import from other unit
  def import_package(package)
    Package.from_other_unit(package).has_greater_version(package).where(:package_branch_id => package.package_branch_id, :shared => true).order("version desc").first
  end
  
  # Return the unit name of where the package is importing from
  def import_package_unit_name(package)
    Unit.where(:id => import_package(package).unit_id).first.name
  end
  
  # Return the version tracker url for this package
  def version_tracker_info_url(package)
    PackageBranch.where(:id => package.package_branch_id).first.version_tracker.info_url
  end
  
  # Need a package and classname to restrieve a list of effected items by Computers, Computer Groups and Bundles
  def get_effected_items(package, className)
    items = Kernel.const_get(className).where(:package_id => package.id) +  Kernel.const_get(className).where(:package_branch_id => package.package_branch_id)
    computer_id = []
    computer_group_id = []
    bundle_id = []
    if items.present?
      items.each do |item|
        computer_id << item.manifest_id if item.manifest_type == "Computer"
        computer_group_id << item.manifest_id if item.manifest_type == "ComputerGroup"
        bundle_id << item.manifest_id if item.manifest_type == "Bundle"
      end
      
      computers = Computer.where(:id => computer_id, :unit_id => current_unit.id)
      computer_groups = ComputerGroup.where(:id => computer_group_id, :unit_id => current_unit.id)
      bundles = Bundle.where(:id => bundle_id, :unit_id => current_unit.id)
    end
    computers.present? ? @computers = computers : @computers = nil
    computer_groups.present? ? @computer_groups = computer_groups : @computer_groups = nil
    bundles.present? ? @bundles = bundles : @bundles = nil
  end
  
  def get_effected_install(package)
    get_effected_items(package, "InstallItem")
    render :partial => 'effected_items', :locals => {:computers => @computers, :computer_groups => @computer_groups, :bundles => @bundles}
  end
  
  def get_effected_uninstall(package)
    get_effected_items(package, "UninstallItem")
    render :partial => 'effected_items', :locals => {:computers => @computers, :computer_groups => @computer_groups, :bundles => @bundles}
  end
  
  def get_effected_optional_install(package)
    get_effected_items(package, "OptionalInstallItem")
    render :partial => 'effected_items', :locals => {:computers => @computers, :computer_groups => @computer_groups, :bundles => @bundles}
  end
  
end