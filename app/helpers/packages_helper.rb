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

	def package_header(package)
    render :partial => 'shared/record_header', :locals => {
                              														:title => package.display_name,
                              														:img => package.icon.public_filename,
                              														:soft_info => package.name,
                              														:bold_info => package.version }
	end
	
	def recent_packages
	 pkgs = Package.recent(current_unit)
	 render :partial => 'recent', :locals  => { :pkgs => pkgs }
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
  
  def scrape_latest_version_info(pkg)
    require 'scrapi'

    # Define scrape for latest version, and download redirect URL
    scraper = Scraper.define do
      process "span.appVersion", :version => :text
      process ".product-quick-links>h2>a", :download_redirect_url => "@href"
      result :version,:download_redirect_url
    end

    # Version tracker URL to application page
    uri = URI.parse("http://www.versiontracker.com/dyn/moreinfo/macosx/#{pkg.version_tracker_id}")

    # Scrape latest version and download redirect URL
    results = scraper.scrape(uri)
    latest_version = results.version

    # Define scrape for latest version, and download redirect URL
    scraper = Scraper.define do
      process "p.contactDevSite>a", :download_url => "@href"
      result :download_url
    end
    
    unless(results.download_redirect_url == nil)
      # Version tracker URL to download redirect
      uri = URI.parse(results.download_redirect_url)

      # Scrape download URL
      download_url = scraper.scrape(uri)
    else
      download_url = nil
    end
    
    {'latest_version' => latest_version, 'download_url' => download_url}
  end
  
  # Checks when versions were last checked and re-checks if within given time
  # Sets session[:versions_checked_at]
  def check_versions?
    seconds_between_checks = 300
    if session[:versions_checked_at].nil?
      # Check versions, if not checked yet
      session[:versions_checked_at] = Time.now.to_i
      true
    elsif session[:versions_checked_at] < (Time.now.to_i - seconds_between_checks)
      # Check versions, if seconds_between_checks has passed
      true
    else
      # Don't check versions
      false
    end
  end
  
  # Check version tracker for package updates, display available updates
  def available_updates
    version_tracker_url = "http://www.versiontracker.com/dyn/moreinfo/macosx/"
    # Get the latest version of all version trackable packages
    pkgs = Pkgsinfo.version_trackable.all(:conditions => {:id => Pkgsinfo.latest_package_ids})
    newer_available = []
    if check_versions?
      session[:newer_versions] = []
      pkgs.each do |pkg|
        info = scrape_latest_version_info(pkg)
        
        # If latest_version or download_url is blank, don't compare versions
        unless(info['latest_version'].blank? or info['download_url'].blank?)
          # Strip ".0" from end of version three times
          formatted_version = pkg.version.sub(/\.0$/,'').sub(/\.0$/,'').sub(/\.0$/,'')
          if info['latest_version'] > formatted_version
            newer_available << pkg
            session[:newer_versions] << {'download_url' => info['download_url'], 
                                          'version' => info['latest_version'], 
                                          'display_name' => pkg.display_name, 
                                          'version_tracker_id' => pkg.version_tracker_id}
          end
        end
      end
    end
    render :partial => 'available_updates', :locals => {:pkgs => newer_available,
                                                        :version_tracker_url => version_tracker_url,
                                                        :newer_versions => session[:newer_versions]}
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
end