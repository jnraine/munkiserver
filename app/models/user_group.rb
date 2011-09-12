class UserGroup < ActiveRecord::Base
  validates :name, :presence => true
  validates :unit_id, :presence => true
  
  has_many :permissions, :as => :principal
  has_many :privileges, :through => :permissions
  has_many :units, :through => :permissions
  has_many :principal_memberships, :class_name => "UserGroupMembership", :dependent => :destroy
  has_many :principals, :through => :principal_memberships
  has_many :group_memberships, :class_name => "UserGroupMembership", :as => :principal
  has_many :groups, :through => :group_memberships, :source => :user_group
  
  belongs_to :unit
  
  accepts_nested_attributes_for :principal_memberships, :allow_destroy => true
  
  validates :name, :presence => true, :unique_as_shortname => true
  validates :shortname, :presence => true, :format => {:with => /^[a-z0-9-]+$/}
  
  scope :where_unit, lambda {|u| where(:unit_id => u.id) }
  
  include Principal
  
  def members
    principal_memberships.map(&:principal)
  end
  
  def sorted_members
    members.sort {|a,b| a.name.downcase <=> b.name.downcase}
  end
  
  # Returns an array of tas option hashes
  def tas_params(environment_id = nil)
    [{:title => "User",
      :model_name => "user_group",
      :attribute_name => "user_ids",
      :select_title => "Select a new member",
      :options =>  User.all.collect {|u| [u.username, u.id] },
      :selected_options => user_ids}]
  end
  
  def user_ids
    users.map(&:id)
  end
  
  def user_ids=(ids)
    self.user_group_memberships = []
    ids.each do |user_id|
      self.user_group_memberships.create({:user_id => user_id})
    end
  end
  
  # Takes a name attribute and returns a valid shortname attribute
  def conform_name_to_shortname(name = nil)
    name ||= self.name
    name.to_s.downcase.lstrip.rstrip.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/,'')
  end
  
  # Overwrite the default name setter to add shortname attribute when creating a name
  def name=(value)
    self.shortname = conform_name_to_shortname(value)
    write_attribute(:name, value)
  end
  
  def to_s
    name
  end
  
  def to_param
    shortname
  end
  
  def self.find_for_show(unit, identifier)
    record = nil
    # Find by ID
    record = self.where_unit(unit).where(:id => identifier).first if identifier.match(/^\d+$/)
    # Find by shortname
    record ||= self.where_unit(unit).where(:shortname => identifier).first
    record
  end
  
  def principal_ids=(principal_ids)
    # Get existing memberships
    existing_memberships = self.principal_memberships
    # Get principals
    principals = parse_principal_ids(principal_ids)
    # Generate principal membership array
    memberships = []
    principals.each do |principal|
      memberships << find_or_retrieve_membership(principal)
    end
    # Write membership array to principal memberships attribute
    self.principal_memberships = memberships
  end
  
  def parse_principal_ids(principal_ids)
    principal_ids.map do |principal_id|
      get_principal(principal_id)
    end
  end
  
  def find_or_retrieve_membership(principal)
    membership = nil
    # Retrieve existing membership for principal
    self.principal_memberships.each do |existing_membership|
      if existing_membership.principal_id == principal.id and existing_membership.principal_type == principal.class.to_s
        membership = existing_membership
        break
      end
    end
    
    # If we didn't find a membership yet, build one
    if membership.nil?
      membership = self.principal_memberships.build(:principal => principal)
    end
    
    # Return membership
    membership
  end
  
  # Give a principal ID and return a principal record
  def get_principal(principal_id)
    principal = nil
    if p_match = principal_id.match(/(.+)-(\d+)/)
      if $1.classify == UserGroup.to_s
        principal = UserGroup.find($2) 
      elsif $1.classify == User.to_s
        principal = User.find($2)
      else
        Exception.new("Invalid principal type passed: #{$1}.  Must be UserGroup or User.")
      end
    end
  end
  
  # All principals, including all users and all user groups within self.unit.  Return records
  # sorted alphabetically.
  def all_principals
    (User.all + UserGroup.where_unit(self.unit)).sort {|a,b| a.name.downcase <=> b.name.downcase}
  end
end
