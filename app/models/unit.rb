class Unit < ActiveRecord::Base
  magic_mixin :client_pref
  
  # Relationships
  has_many :computers, :dependent => :destroy
  has_many :computer_groups, :dependent => :destroy
  has_many :bundles, :dependent => :destroy
  has_many :packages, :dependent => :destroy
  
  has_many :memberships, :dependent => :destroy
  has_many :users, :through => :memberships
  
  has_one :settings, :dependent => :destroy, :class_name => "UnitSetting", :autosave => true
  accepts_nested_attributes_for :settings, :allow_destroy => true
  
  validates :name, :presence => true, :unique_as_shortname => true
  validates :description, :presence => true
  validates :shortname, :presence => true, :format => {:with => /^[a-z0-9-]+$/}
  
  before_save :check_settings
  
  # Takes a name attribute and returns a valid shortname attribute
  def conform_name_to_shortname(name = nil)
    name ||= self.name
    name.to_s.downcase.lstrip.rstrip.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/,'')
  end
  
  # Overwrite the default name setter to add shortname attribute when creating a name
  def name=(value)
    self.shortname = conform_name_to_shortname(value)
    write_attribute(:name,value)
  end
  
  # Returns the membership that self and user share
  def membership(user)
    memberships.find_by_user_id(user.id)
  end
  
  # Ensures user is a valid member of this unit
  def member?(user)
    user_ids.include?(user.id)
  end
  
  # Alias to user association getter
  def members
    users
  end
  
  # Alias to user association setter
  def members=(value)
    self.users = value
  end
  
  # Returns an array of tas option hashes
  def tas_params(environment_id = nil)
    [{:title => "Users",
      :model_name => "unit",
      :attribute_name => "user_ids",
      :select_title => "Select a new member",
      :options =>  User.all.collect {|u| [u.username, u.id] },
      :selected_options => user_ids}]
  end
  
  # Checks if a unit has a settings association
  # and creates on if it doesn't
  def check_settings
    init_settings if settings.nil?
  end
  
  # Initialize default settings
  def init_settings
    us = UnitSetting.new
    self.settings = us
  end

  def to_s
    name
  end
  
  # Generate key using the User.random_string method
  def self.generate_key
    User.random_string(30)
  end
  
  def self.dormant_computers_mailers
    Unit.all.map(&:dormant_computers_mailer)
  end
  
  def dormant_computers_mailer
    AdminMailer.dormant_computers(self)
  end
  
  def to_param
    shortname
  end
end

