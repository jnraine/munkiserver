# PackageBranch records don't belong to a specific unit or environment but an specific instance can be
# scoped to return only results from a specific unit or environment
class PackageBranch < ActiveRecord::Base
  include HasAUnit

  validates_presence_of :name, :display_name, :package_category_id
  validates_uniqueness_of :name, :scope => [:unit_id]
  validates_format_of :name, :with => /^[^ -.]+$/, :message => "must not contain spaces or hyphens or dots"
  
  attr_accessible :name, :display_name, :package_category_id
  attr_accessor :environment_id
  
  # Relationships
  has_many :install_items, :dependent => :destroy
  has_many :uninstall_items, :dependent => :destroy
  has_many :managed_update_items, :dependent => :destroy
  has_many :optional_install_items, :dependent => :destroy
  has_many :require_items, :dependent => :destroy
  has_many :update_for_items, :dependent => :destroy
  has_many :notifications, :as => :notified
  has_many :packages, :order => "version DESC", :dependent => :destroy
  has_many :shared_packages, :class_name => "Package", :conditions => {:shared => true}
  has_one :version_tracker, :dependent => :destroy, :autosave => true
  
  belongs_to :package_category

  scope :find_for_index, lambda {|unit, env| has_versions.unit(unit).environment(env).order("name ASC").includes({:packages => [:environment, :package_branch]}, :package_category) }
  scope :environment, lambda {|env| joins(:packages).where(:packages => {:environment_id => env.id}).uniq }
  scope :has_versions, where('(SELECT COUNT(*) FROM `packages` WHERE `packages`.`package_branch_id` = `package_branches`.`id`) > 0')
  scope :has_no_versions, where('(SELECT COUNT(*) FROM `packages` WHERE `packages`.`package_branch_id` = `package_branches`.`id`) = 0')
  scope :shared, includes(:packages).where("packages.shared" => true)

  # Conforms a string to the package branch name constraints
  # => Replaces anything that are not alpheranumrical to underscores
  def self.conform_to_name_constraints(name)
    name.downcase.gsub(/[^A-Za-z0-9_]+/,"_")
  end
  
  # Check if there exists a pacakge branch display name that matches the 
  # current package branch name, if found, return a new package branch 
  # display name follow by appending time stamp
  def self.conform_to_display_name_constraints(display_name,id)
    if PackageBranch.where(:display_name => display_name).where("id <> ?", id.to_i).present?
      display_name = "#{display_name}_#{Time.zone.now.to_s}"
    else
      display_name
    end
  end
  
  def latest
    packages.limit(1).first
  end
  
  # Get the latest package within a unit and environment
  def latest_where_unit_and_environment(unit,env)
    latest_where_unit(unit).where(:environment_id => env.id)
  end
  
  def latest_where_unit(unit)
    packages.where(:unit_id => unit.id).order('version desc').limit(1).first
  end
  
  # Extends the functionality of the association dynamic method to
  # return only the packages that match the passed unit member
  def packages_like_unit_member(um)
    packages.where(:environment_id => um.environment_id, :unit_id => um.unit_id)
  end
  
  def packages_where_unit_and_environment(unit,environment)
    packages.where(:environment_id => environment.id, :unit_id => unit.id)
  end
  
  # Return all the packages that are shared and from the given unit
  def shared_packages_from_unit(unit)
    Package.shared.where(:package_branch_id => id, :unit_id => unit.id).order("version DESC")
  end
  
  # Virtual attribute that retrieves the web ID from the version tracker
  # record associated to this package branch
  def version_tracker_web_id
    version_tracker.web_id = version_tracker.web_id unless version_tracker.nil?
  end
  
  def version_tracker_web_id=(value)
    version_tracker.web_id = value unless version_tracker.nil?
  end

  # Virtual attributes that retrieves the web URL from the version tracker
  def version_tracker_web_url
    version_tracker.download_url unless version_tracker.nil?
  end
  
  def version_tracker_web_url=(url)
    version_tracker.download_url = url unless version_tracker.nil?
  end
  
  # True if a newer version is available in this branch
  def new_version?(unit = nil)
    if version_tracker.nil? or version_tracker.version.nil?
      return false
    else
      version_string = vtv(unit)
      if version_string.present?
        version_string.version_string_comparison(version_tracker.version) == -1
      else
        raise Exception.new("No package found with package branch of #{self} inside #{unit} unit")
      end
    end
  end
  
  # Returns latest package or package with
  # ID of arg 1 (if it exists)
  def package(unit_member = nil, id = nil)
    p = packages

    # Specify a certain ID
    p = p.where(:id => id) unless id.nil?    

    # Limiting scope to that of unit_member or current scope (defined by unit_id and environment_id)
    if unit_member != nil
      p = p.where(:environment_id => unit_member.environment_id)
      p = p.where(:unit_id => unit_member.unit_id)
    elsif scoped?
      p = p.where(:environment_id => @environment_id)
      p = p.where(:unit_id => @unit_id)
    end
    p.first
  end
  
  # Grabs vtv from latest package
  def vtv(unit = nil)
    p = unit.present? ? latest_where_unit(unit) : latest
    p.vtv unless p.nil?
  end
  
  # Get the associated environment
  def environment
    Environment.find_by_id(@environment_id)
  end
  
  # True if there is a newer version of in this package branch
  # available from a unit different than unit
  def new_version_shared?(unit)
    # Latest package from unit
    latest_package = self.latest_where_unit(unit)
    # Packages from this branch, which are shared, not part of unit
    latest_shared_package = self.all_packages.shared.where("unit_id != #{unit.id}").order("version desc").limit(1).first
    # latest_package or latest_shared_package might be nil.  Let's be lazy and just rescue and assume false
    begin
      latest_package.version < latest_shared_package.version
    rescue NoMethodError
      false
    end
  end
  
  # Gets packages that have available updates.  If no unit is 
  # specified, all units are inspected.
  def self.available_updates(unit = nil)
    packages_with_updates = []
    if unit.present?
      latest_packages = Package.latest_where_unit(unit)
      packages_with_updates = latest_packages.delete_if {|p| !p.new_version? }      
    else
      Unit.all.each do |unit|
        latest_packages = Package.latest_where_unit(unit)
        packages_with_updates += latest_packages.delete_if {|p| !p.new_version? }
      end
    end
    packages_with_updates
  end
  
  def self.cached_available_updates(unit = nil)
    Rails.cache.fetch("available-updates-for-unit-id-#{unit.id}", :expires_in => 4.hours) do
      self.available_updates(unit)
    end
  end
  
  # Return the package branches available to a given unit member
  # Doesn't return an ActiveRecord::Relation (search cannot be 
  # done using only SQL)
  def self.unit_member(unit_member)
    Package.unit(unit_member.unit).environments(unit_member.environments).map { |e| e.package_branch }.uniq
  end
  
  # Get package branches with packages in a specified unit and environment
  # TO-DO Not very efficient, could be refactored
  def self.unit_and_environment(unit,environment)
    Package.unit(unit).environment(environment).uniq_by {|branch| branch.id }
  end
  
  # Overrides default to string method.  Specifies version if this package
  # isn't the latest of the current units
  def to_s(style = nil)    
    case style
      when :pretty then display_name
      else name
    end
  end
  
  def to_param
    name
  end
  
  def to_params
    {:unit_shortname => unit.shortname,
     :name => name}
  end
  
  def obsolete?
    packages.empty? and install_items.empty? and uninstall_items.empty? and managed_update_items.empty? and optional_install_items.empty? and require_items.empty? and update_for_items.empty?
  end
  
  def icon
    version_tracker.icon unless version_tracker.nil?
  end
end
