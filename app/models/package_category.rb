class PackageCategory < ActiveRecord::Base
  belongs_to :icon
  
  # Return the default package category
  # Grabs a record named "Misc" or the first record
  def self.default(installer_type = nil)
    d = nil
    # Depending on the installer_type, assign a specific package category
    case installer_type
      when "appdmg" then d = self.find_by_name("Application")
      when "adobeuberinstaller" then d = self.find_by_name("Application")
      else d = self.find_by_name("Misc")
    end
    # If the above assignment fails, grab the first available package category
    d ||= self.first
    d
  end
  
  def to_s
    name
  end
end

