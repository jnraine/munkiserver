class UserGroup < ActiveRecord::Base
  validates :name, :presence => true
  validates :unit_id, :presence => true
  
  has_many :permissions, :as => :principal
  has_many :privileges, :through => :permissions
  has_many :units, :through => :permissions
  has_many :principal_memberships, :class_name => "UserGroupMembership", :dependent => :destroy, :include => :principal
  has_many :principals, :through => :principal_memberships
  has_many :group_memberships, :class_name => "UserGroupMembership", :as => :principal
  has_many :groups, :through => :group_memberships, :source => :user_group
  
  belongs_to :unit
  
  accepts_nested_attributes_for :principal_memberships, :allow_destroy => true
  
  validates :name, :presence => true, :unique_as_shortname => true
  validates :shortname, :presence => true, :format => {:with => /^[a-z0-9-]+$/}
  
  scope :where_unit, lambda {|u| where(:unit_id => u.id) }
  
  def members
    principal_memberships.map(&:principal)
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
  
  # For nested association deletion, default to false
  def _destroy
    false
  end
  
  def css_class
    self.class.to_s.underscore.gsub("_","-") + "-principal"
  end
  
  # Returns a unique principal ID for this principal
  def principal_id
    self.class.to_s.underscore.gsub("_","-") + "-#{id}"
  end
end
