class ProcessPackageUpload
  attr_accessor :params, :package, :error_message
  
  def initialize(params)
    @params = Parameters.new(params)
  end

  def process
    params.validate
    params.package_file = PackageFileHandler.handle(params.package_file, params.fileurl)
    params.pkginfo = PkginfoGenerator.generate(params.package_file, params[:pkginfo_file], params[:makepkginfo_options])
    self.package = PackageAssembler.assemble(params.package_file, params.pkginfo, params[:special_attributes])
  rescue ProcessPackageUpload::Error => e
    self.error_message = e.message
    false
  end
  
  def processed?
    package.present? and error_message.blank?
  end
  
  private
  class Parameters
    attr_reader :hash
    attr_accessor :pkginfo, :package_file
    
    def initialize(hash)
      @hash = defaults.deep_merge(hash)
    end
    
    def defaults
      {:special_attributes => {:environment_id => Environment.start.id}}
    end

    # Checks to ensure what should be present is. If something is missing, raise 
    # Error exception.
    def validate
      raise Error.new("Please select a file") if hash[:package_file].nil? and hash[:fileurl].empty?
      raise Error.new("Must provide a special attributes") if hash[:special_attributes].nil?
      raise Error.new("Must provide a unit ID") if hash[:special_attributes][:unit_id].nil?
      raise Error.new("Must provide an environment ID") if hash[:special_attributes][:environment_id].nil?
    end
    
    def package_file
      @package_file ||= hash[:package_file]
    end
    
    def fileurl
      @fileurl ||= hash[:fileurl]
    end
    
    def [](key)
      hash[key]
    end
  end
  
  class PkginfoGenerator
    class << self
      def generate(package_file, pkginfo_file, cmd_line_options)
        if Munki::Application::MUNKI_TOOLS_AVAILABLE and pkginfo_file.nil?
          process_package_file(package_file, cmd_line_options)
        elsif pkginfo_file.present?
          process_pkginfo_file(pkginfo_file)
        else
          raise Error.new("Package file and/or pkginfo file missing")
        end
      end
    
      # Process package_file with makepkginfo on localhost
      def process_package_file(package_file, cmd_line_options)
        cmd_line_arguments = cmd_line_arguments(cmd_line_options)

        # Run makepkginfo
        out_log = Tempfile.new("out_log")
        error_log = Tempfile.new("error_log")
        makepkginfo_succeeded = system("#{Munki::Application::MAKEPKGINFO} #{cmd_line_arguments} '#{package_file.path}' 1> '#{out_log.path}' 2>'#{error_log.path}'")
        exit_status = $?.exitstatus

        # If there was a problem, cleanup, then raise an error
        if exit_status != 0
          # Remove package and raise error
          FileUtils.rm(package_file.path)
          raise Error.new("Munki tools were unable to process package file: " + out_log.read + "\n" + error_log.read)
        end

        process_pkginfo_file(out_log)
      end
    
      # Generate command-line options string from hash
      def cmd_line_arguments(cmd_line_options)
        cmd_line_options_array = cmd_line_options.map do |k,v| 
          v = v.gsub(/ /,'\ ')
          "--#{k}=#{v}" unless v.blank?
        end
      
        cmd_line_options_array.compact.join(" ")
      end
    
      # Convert pkginfo file to hash
      def process_pkginfo_file(pkginfo_file)
        pkginfo_hash = nil

        # Parse plist
        begin
          pkginfo_hash = Plist.parse_xml(pkginfo_file.read.to_utf8)
        rescue Exception => e
          raise Error.new("Unable to parse pkginfo file -- Plist.parse_xml raised an exception: #{e}")
        end

        # Make sure pkginfo_hash isn't nil
        if pkginfo_hash.nil?
          raise Error.new("Unable to parse pkginfo file -- Plist.parse_xml returned nil: pkginfo file probably empty")
        end

        pkginfo_hash
      end
    end
  end
  
  class PackageFileHandler
    class << self
      # Renames and moves temporary files to the appropriate package store. Returns
      # a File object for newly renamed/moved file
      def handle(package_file, fileurl)
        destination_path = nil
        
        # Download DMG from URL
        if package_file.nil? and not fileurl.empty?
          file = Tempfile.new('munkiserver')
          file.binmode
          file << open(fileurl).read
          
          package_file = OpenStruct.new
          package_file.original_filename = File.basename(fileurl)
          package_file.tempfile = OpenStruct.new
          package_file.tempfile.path = file.path
          Rails.logger.warn package_file
        end

        # Get the absolute path for the package store
        unique_name = uniquify_name(package_file.original_filename)
        destination_path = Pathname.new(Munki::Application::PACKAGE_DIR + unique_name)

        # Move tmp_file to the package store
        begin
          FileUtils.mv package_file.tempfile.path, destination_path
          FileUtils.chmod 0644, destination_path
        rescue Errno::EACCES => e
          raise Error.new("Unable to write to package store")
        end

        # Return the package as a File object
        begin
          File.new(destination_path)
        rescue
          raise Error.new("Unable to read #{destination_path}")
        end
      end
      
      # Create a unique name from a string by prepending the current timestamp
      # and adding a random number
      def uniquify_name(name)
        Time.now.to_s(:ordered_numeric) + rand(10001).to_s + "_" + name
      end
    end
  end
  
  class PackageAssembler
    class << self
      def assemble(package_file, pkginfo, special_attributes)
        package = Package.new
        pkginfo.delete("catalogs")
        branch_attributes = {:name => pkginfo.delete("name"),
                             :display_name => pkginfo.delete("display_name"),
                             :unit_id => special_attributes[:unit_id], 
                             :package_category_id => PackageCategory.default(pkginfo["installer_type"]).id}
        package.package_branch = retrieve_package_branch(branch_attributes)
        
        pkginfo.each do |k,v|
          unless Package.known_attributes.include?(k)
            package.raw_tags = package.raw_tags.merge({k => v})
            pkginfo.delete(k)
            package.raw_mode_id = 1 # Change raw_mode to append
          end
        end
      
        package.attributes = pkginfo
        package.installer_item_location = File.basename(package_file.path)
        package.add_raw_tag("installer_item_hash", Digest::SHA256.file(package_file.path).hexdigest)
        package = apply_special_attributes(package, special_attributes)
        package = apply_previous_version_attributes(package)

        if package.valid?
          package.save
        else
          raise Error.new("Unable to save invalid package: #{package.errors.full_messages.join(", ")}")
        end
        
        package
      end
    
      # Create a new package branch if not existing
      # else pick the existing package branch and assign to the package
      def retrieve_package_branch(attributes)
        attributes[:name] = PackageBranch.conform_to_name_constraints(attributes[:name])
        
        if branch = PackageBranch.where(:name => attributes[:name], :unit_id => attributes[:unit_id]).first
          branch
        else
          create_package_branch(attributes)
        end
      end
    
      def create_package_branch(attributes)
        PackageBranch.create! do |branch|
          branch.name = attributes[:name]
          branch.display_name = attributes[:display_name] || attributes[:name]
          branch.unit_id = attributes[:unit_id]
          branch.package_category_id = attributes[:package_category_id]
          branch.version_tracker = branch.build_version_tracker
        end
      end

      # Applies special attributes (unit, environment, other) to a package.
      def apply_special_attributes(package, attributes = {})
        attributes.each do |attribute,value|
          package.send("#{attribute}=",value)
        end
        package
      end

      # Apply inherited attributes (as defined by inherited_attributes)
      # from an older version from the package's package branch and unit
      def apply_previous_version_attributes(package)
        previous_version = Package.where(:package_branch_id => package.package_branch_id, :unit_id => package.unit_id).order('version DESC').first
        if previous_version.present?
          Package.inherited_attributes.each do |attr|
            package.send("#{attr}=",previous_version.send(attr)) unless previous_version.send(attr).blank?
          end
        end
        package
      end
    end
  end
  
  class Error < Exception;end
end