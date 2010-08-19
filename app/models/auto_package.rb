# Auto package takes a file (in the form of a URL or path) and determines if it can automatically package it
# and add it to the munki server.
# 
# Cases covered:
# => URL to .dmg files
# => URL to .zip files
# => Firefox download redirect page
# 
# Cases that need to be accounted for:
# => Source forge download redirect page
# => VLZ download mirror page
module AutoPackage
  require 'open-uri'
  
  UNZIP = "/usr/bin/unzip"
  SUPPORTED_EXTENSIONS = ["dmg","zip"]
  
  # Downloads file from a URL and turns it into a Package record
  def self.from_url(url)
    # For special cases, reformat the URL
    url = reformat_url(url)
    # Derive original filename
    begin
      original_filename = url.match(/(\/)([^\/]+)$/)[2]
    rescue NoMethodError
      raise AutoPackageError.new("Could not derive original filename from URL (#{url})")
    end
    # Derive extension
    extension = grep_extension(original_filename)
    unless SUPPORTED_EXTENSIONS.include?(extension)
      if extension == ''
        raise AutoPackageError.new("No extension found on download URL: #{url}")
      else
        raise AutoPackageError.new("#{extension} is not a supported extension for auto packaging!")
      end
    end
    # Download package
    begin
      f = open(url)
    rescue Errno::ENOENT
      raise AutoPackageError.new("Could not find URL (#{url})")
    end
      
    # Temp stuff
    tmp_dir = Pathname.new(File.dirname(f.path))
    tmp_path = tmp_dir + original_filename
    # Rename temp file
    FileUtils.mv(f.path,tmp_path)
    # Close old file handle
    f.close
    # Open new file handle
    f = File.open(tmp_path)
    self.from_path(tmp_path)
  end
  
  # Reforms url for special cases, such as firefox download.
  # 
  # When adding another case, do the following:
  # => Create #{url_type}_url? method that is true or false if URL is that type
  # => Create format_#{url_type}_url method that takes a url of that type and returns a formatted version
  # => Add a if #{url_type} then return #{url_type.to_sym}
  def self.reformat_url(url)
    url_type = url_type(url)
    # Reformat the URL based on the type
    send "format_#{url_type}_url", url
  end
  
  # Return symbol representation of url type
  def self.url_type(url)
    if firefox_url?(url)
      return :firefox
    else
      :normal
    end
  end
  
  # Don't do anything to the URl.  We only have this to simplify the reformat_url method
  def self.format_normal_url(url)
    url
  end
  
  # True if resembles firefox url
  def self.firefox_url?(url)
    url.match(/http:\/\/www\.mozilla\.com\/[^\/]*\/?products\/download\.html.+/) != nil
  end
  
  # Take a firefox URL type and return a formatted one
  def self.format_firefox_url(url)
    get_string = url.match(/(http:\/\/www\.mozilla\.com\/[^\/]*\/?products\/download\.html)(.+)/)[2]
    version = get_string.match(/(\?product=firefox-)([\d\.]+)(.+)/)[2]
    # Add version to proper URL
    "http://releases.mozilla.org/pub/mozilla.org/firefox/releases/#{version}/mac/en-US/Firefox%20#{version}.dmg"
  end
  
  # Derives extension from string
  def self.grep_extension(s)
    match = s.to_s.match(/(\.)([a-zA-Z]+$)/)
    match[2] unless match.nil?
  end
  
  def self.from_path(path)
    extension = grep_extension(path)
    if extension == "dmg"
      self.dmg(path)
    elsif extension == "zip"
      self.zip(path)
    else
      raise IncompatiblePackageType("Please supply a supported item: #{SUPPORTED_EXTENSIONS.join(", ")}")
    end
  end
  
  # Auto package a dmg file at path
  def self.dmg(path)
    # Create a file object
    f = File.new(path)
    # Upload to server
    Package.upload(f)
  end
  
  # Auto package a zip file at path
  def self.zip(path)
    # Unzip
    # Get original filename without extension
    original_name = File.basename(path).sub(/\.[A-Za-z]+$/,'')
    # Remove extension from path
    extract_dir = File.dirname(path) + "/" + original_name
    # Add date stamp
    # extract_dir = File.dirname(extract_dir) + "/" + Time.now.to_s(:ordered_numeric) + File.basename(extract_dir)
    # Create destination directory
    extract_dir = self.unzip(path,extract_dir)
    # Make sure we're OK
    if extract_dir.nil?
      raise AutoPackageError.new("Unable to unzip #{path}")
    end
    
    # Wrap in a DMG
    dmg_path = wrap_contents_in_dmg(extract_dir)
    if dmg_path.nil?
      raise AutoPackageError.new("Unable to wrap #{extract_dir} into a DMG")
    end
    self.dmg(dmg_path)
  end
  
  # Takes a path to a directory and creates a DMG from everything inside that directory
  # Returns dmg path if success, nil if failure
  def self.wrap_contents_in_dmg(path)
    dmg_path = path + ".dmg"
    exit = `hdiutil create -srcfolder #{path} #{dmg_path} >> /dev/null; echo $?`.chomp.to_i
    if exit == 0
      dmg_path
    end
  end
  
  # Unzip a file to destination.  Returns destination directory if success, otherwise, nil
  def self.unzip(path_to_zip,extract_dest)
    # logger.info("Unzipping #{path_to_zip} into #{extract_dest}")
    exit = `#{UNZIP} -o #{path_to_zip} -d #{extract_dest} >> /dev/null; echo $?`.chomp.to_i
    if exit == 0
      extract_dest
    end
  end
end