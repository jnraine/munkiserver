module AutoPackage
  require 'open-uri'
  
  SUPPORTED_EXTENSIONS = ["dmg"]
  
  # Downloads file from a URL and turns it into a Package record
  def self.from_url(url)
    # Derive original filename
    begin
      original_filename = url.match(/(\/)([^\/]+)$/)[2]
    rescue NoMethodError
      raise AutoPackageError.new("Could not derive original filename from URL (#{url})")
    end
    # Derive extension
    extension = grep_extension(original_filename)
    unless SUPPORTED_EXTENSIONS.include?(extension)
      raise AutoPackageError.new("#{extension} is not a supported extension for auto packaging!")
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
  
  # Derives extension from string
  def self.grep_extension(s)
    match = s.to_s.match(/(\.)([a-zA-Z]+$)/)
    match[2] unless match.nil?
  end
  
    def self.from_path(path)
    extension = grep_extension(path)
    if extension == "dmg"
      f = File.new(path)
      Package.upload(f)
    else
      raise IncompatiblePackageType
    end
  end
end

class AutoPackageError < Exception
end