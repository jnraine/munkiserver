# A helper class that connects the controller to the model in a special way
# thus cleaning up the implementation of the controller quite a bit.
class PackageService
  attr_accessor :package, :attr

  # Creates a BundleService object that does the extra params hash handling
  # duties (such as querying for PackageBranch records)
  # TO-DO Optimization: if the IDs were used to create association objects directly, it would save some work
  def initialize(package, attributes)
    @package = package
    @attr = attributes
    
    # Retrieve PackageBranch records for all installs if edit_*installs is not nil
    @attr[:upgrade_for] = PackageService.parse_package_strings(@attr[:update_for]) if @attr[:upgrade_for] != nil
    @attr[:requires] = PackageService.parse_package_strings(@attr[:requires]) if @attr[:requires] != nil
  end
  
  # Takes an array of strings and returns either a package or a package branch
  # depending on the format of the string.
  # => Package record returned if matching: "#{package_branch_name}-#{version}"
  # => PackageBranch record returned if matching: "#{package_branch_name}"
  def self.parse_package_strings(a)
    installs = []
    a.each do |name|
      if split = name.match(/(.+)(-)(.+)/)
        # For packages
        pb = PackageBranch.where(:name => split[1]).limit(1).first
        p = Package.where(:package_branch_id => pb.id, :version => split[3]).first
        installs << p unless p.nil?
      else
        # For package branches
        pb = PackageBranch.where(:name => name).limit(1).first
        installs << pb unless pb.nil?
      end
    end
    installs
  end
  
  # Perform a save on the @Qpackage object (after assigning all the *installs)
  def save
    @package.update_attributes(@attr)
  end
end