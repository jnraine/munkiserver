class Unit < ActiveRecord::Base
  # Relationships
  has_many :computers, :dependent => :destroy
  has_many :computer_groups, :dependent => :destroy
  has_many :bundles, :dependent => :destroy
  has_many :packages, :dependent => :destroy
  
  has_many :memberships, :dependent => :destroy
  has_many :users, :through => :memberships
  
  has_one :settings, :dependent => :destroy, :class_name => "UnitSetting", :autosave => true
  
  validates_uniqueness_of :name, :case_sensitive => true
  validates_presence_of :name, :description
  # A list of ACL attribute names
  # This list of names get turned into methods that check
  # if a given user has permission to complete a given action
  ACLS = [:create_computer,:read_computer,:edit_computer,:destroy_computer,
          :create_bundle,:read_bundle,:edit_bundle,:destroy_bundle,
          :create_computer_group,:read_computer_group,:edit_computer_group,:destroy_computer_group,
          :create_package,:read_package,:edit_package,:destroy_package]
  
  before_save :check_settings
  after_save :require_computer_group
  
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
  
  # Creates default computer group if there are none assigned to this unit
  def require_computer_group
    create_default_computer_group if self.computer_groups.count == 0
  end
  
  # Attempts to create and save a computer group named "Default"
  def create_default_computer_group
    cg = ComputerGroup.unit(self).find_by_name("Default")
    cg ||= ComputerGroup.new({:name => "Default", :unit_id => self.id, :environment_id => Environment.first.id})
    cg.save and self.save
  end
  
  # Returns an array of tas option hashes
  def tas_params
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
  
  # Builts permission checking methods based on ACLS constant
  def self.construct_acl_methods
    ACLS.each do |acl|
      # Checks if the current user has permission to do something
      define_method "#{acl.to_s}?" do |user|
        member?(user) and membership(user).edit_computer
      end
    end
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
  
  # def to_param
  #   name
  # end
  
  construct_acl_methods
end

# == Schema Information
#
# Table name: units
#
#  id               :integer         not null, primary key
#  name             :string(255)
#  description      :text
#  key              :string(255)
#  unit_member_id   :integer
#  unit_member_type :integer
#  created_at       :datetime
#  updated_at       :datetime
#

