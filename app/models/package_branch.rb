# PackageBranch records don't belong to a specific unit or environment but an specific instance can be
# scoped to return only results from a specific unit or environment
class PackageBranch < ActiveRecord::Base
  # Validations
  validates_presence_of :name
  validates_uniqueness_of :name
  
  attr_protected :id, :name
  
  attr_accessor :unit_id, :environment_id
  
  # Relationships
  has_many :install_items, :dependent => :destroy
  has_many :uninstall_items, :dependent => :destroy
  has_many :user_install_items, :dependent => :destroy
  has_many :user_uninstall_items, :dependent => :destroy
  has_many :user_allowed_items, :dependent => :destroy
  has_many :require_items, :dependent => :destroy
  has_many :update_for_items, :dependent => :destroy
  has_many :all_packages, :order => 'version desc', :class_name => "Package"
  has_one :new_version, :dependent => :destroy, :class_name => "VersionTracker"
  
  before_save :verify_display_name
  
  # Returns the latest package (based on version)
  # in the package branch.  Results are scoped if scoped? returns true
  def latest(unit_member = nil)
    package(unit_member)
  end
  
  # Get the latest package within a unit and environment
  def latest_where_unit_and_environment(unit,env)
    packages.where(:unit_id => unit.id, :environment_id => env.id).order('version desc').first
  end
  
  # Extends the functionality of the association dynamic method to
  # return only the packages that match the passed unit member
  def packages_like_unit_member(um)
    packages.where(:environment_id => um.environment_id, :unit_id => um.unit_id)
  end
  
  def packages_where_unit_and_environment(unit,environment)
    packages.where(:environment_id => environment.id, :unit_id => unit.id)
  end
  
  # Provides a scoped (if applicable) search in the Package association
  def packages
    if scoped?
      all_packages.where(:unit_id => @unit_id, :environment_id => @environment_id)
    else
      all_packages
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
  
  # Checks if display_name is blank, if so, it makes it the value of name
  def verify_display_name
    self.display_name = self.name if self.display_name.blank?
  end
  
  # Checks if a new version is available
  def new_version_available?
    new_version != nil
  end

  # Sets iVars @environment_id and @unit_id to bind this record, temporarily, to a certain scope
  def bind_to_scope(param1, param2 = nil)
    if param2.nil?
      # If only one param passed, assume it to be a unit_member
      @environment_id = param1.environment_id
      @unit_id        = param1.unit_id
    else
      # If both, assume first to be unit, second to be environment
      @unit_id        = param1.id
      @environment_id = param2.id
    end
    self.scoped?
  end
  
  # Return boolean if @unit_id and @environment_id is set
  def scoped?
    @environment_id != nil and @unit_id != nil
  end
  
  # Get the associated environment
  def environment
    Environment.find_by_id(@environment_id)
  end
  
  # Get the associated unit
  def unit
    Unit.find_by_id(@unit_id)
  end
  
  # Return the package branches available to a given unit member
  # Doesn't return an ActiveRecord::Relation (search cannot be 
  # done using only SQL)
  def self.unit_member(unit_member)
    Package.unit(unit_member.unit).environments(unit_member.environments).map { |e| e.package_branch }.uniq
  end
  
  # Get package branches with packages in a specified unit and environment
  # TO-DO Not very efficient, could be refactored
  def self.unit_and_environment(unit,environment, scope_results = true)
    pbs = Package.unit(unit).environment(environment).map {|p| p.package_branch }.uniq
    pbs.each {|pb| pb.bind_to_scope(unit,environment) if scope_results }
    pbs
  end
  
  def to_s
    name
  end
end