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

	def package_header(package, editable = nil)
	  packages = Package.where(:package_branch_id => package.package_branch_id, :unit_id => package.unit_id).order("version ASC")
	  editable ||= false
    render :partial => 'record_header', :locals => {
                              														:title => package.display_name,
                              														:img => package.icon,
                              														:soft_info => package.name,
                              														:bold_info => package.version,
                              														:packages => packages,
                              														:editable => editable }
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
      return true
    else
      return false
    end
  end
  
  # Determine to show import or update links based on the versions of the available import package and version tracker version
  def update_or_import(package)
    # if the package has other greather version shared packages and has newer version tracker version
    if import_package(package).present? and package.package_branch.new_version?
      # if the version tracker has higher version than the shared package
      if package.package_branch.version_tracker.version > import_package(package).version
        render :partial => 'update_available_link', :locals => {:package => package }
      else
        render :partial => 'import_available_link', :locals => {:package => package }
      end
    elsif import_package(package).present?
      render :partial => 'import_available_link', :locals => {:package => package }
    elsif package.package_branch.new_version?
      render :partial => 'update_available_link', :locals => {:package => package }
    else
      # show nothing
    end
  end
  
  # Return latest package if available to import from other unit
  def import_package(package)
    result = Package.from_other_unit(package).has_greater_version(package).where(:package_branch_id => package.package_branch_id, :shared => true).order("version desc").first
    if result.present?
      result.version > package.latest_in_unit.version ? result : nil
    end
  end
  
  # Return the unit name of where the package is importing from
  def import_package_unit_name(package)
    Unit.where(:id => import_package(package).unit_id).first.name
  end
  
  # Need a package and classname to restrieve a list of effected items by Computers, Computer Groups and Bundles
  def get_effected_items(package, classname)
    # Make sure the selected pacakge is bounded to current unit and environment
    if package.latest_in_unit_and_environment?
      # If package id is blank, than default to the highest version of the package that are blong to current unit & environment
      items = classname.constantize.where(:package_branch_id => package.package_branch_id, :package_id => nil)
    else
      # If package id is given then find by id
      items = classname.constantize.where(:package_id => package.id)
    end
    computer_id = []
    computer_group_id = []
    bundle_id = []
    if items.present?
      items.each do |item|
        computer_id << item.manifest_id if item.manifest_type == "Computer"
        computer_group_id << item.manifest_id if item.manifest_type == "ComputerGroup"
        bundle_id << item.manifest_id if item.manifest_type == "Bundle"
      end
      computers = Computer.where(:id => computer_id, :unit_id => current_unit.id, :environment_id => package.environment_id)
      computer_groups = ComputerGroup.where(:id => computer_group_id, :unit_id => current_unit.id, :environment_id => package.environment_id)
      bundles = Bundle.where(:id => bundle_id, :unit_id => current_unit.id, :environment_id => package.environment_id)
    end
    # Turn to instance variable so other methods can have access to, make sure not cache any results
    computers.present? ? @computers = computers : @computers = nil
    computer_groups.present? ? @computer_groups = computer_groups : @computer_groups = nil
    bundles.present? ? @bundles = bundles : @bundles = nil
  end
  
  # Get a list of Computers, Computer Groups and Bundles that have this package set to install
  def get_effected_install(package)
    get_effected_items(package, "InstallItem")
    render :partial => 'effected_items', :locals => {:computers => @computers, 
                                                     :computer_groups => @computer_groups, 
                                                     :bundles => @bundles}
  end
  
  # Get a list of Computers, Computer Groups and Bundles that have this package set to unisntall
  def get_effected_uninstall(package)
    get_effected_items(package, "UninstallItem")
    render :partial => 'effected_items', :locals => {:computers => @computers, 
                                                     :computer_groups => @computer_groups, 
                                                     :bundles => @bundles}
  end
  
  # Get a list of Computers, Computer Groups and Bundles that have this package set as optional install
  def get_effected_optional_install(package)
    get_effected_items(package, "OptionalInstallItem")
    render :partial => 'effected_items', :locals => {:computers => @computers, 
                                                     :computer_groups => @computer_groups, 
                                                     :bundles => @bundles}
  end
  
end