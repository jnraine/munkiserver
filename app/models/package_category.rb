class PackageCategory < ActiveRecord::Base
  belongs_to :icon
  
  # Return the default package category
  # Grabs a record named "Misc" or the first record
  def self.default(installer_type = nil)
    category = find_by_name("Application") if installer_type.to_s.match(/appdmg|copy_from_dmg|adobeuberinstaller/)
    category ||= self.first
  end
  
  def to_s
    name
  end
end

