class Unit < ActiveRecord::Base
  magic_mixin :client_pref
  
  # Relationships
  has_many :computers, :dependent => :destroy
  has_many :computer_groups, :dependent => :destroy
  has_many :bundles, :dependent => :destroy
  has_many :packages, :dependent => :destroy
  has_many :principals, :through => :permissions
  
  scope :from_other_unit, lambda {|u| where("id != ?", u.id)}
  
  validates :name, :presence => true, :unique_as_shortname => true
  validates :description, :presence => true
  validates :shortname, :presence => true, :format => {:with => /^[a-z0-9-]+$/}
  
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
  
  # Returns an array of tas option hashes
  def tas_params(environment_id = nil)
    [{:title => "Users",
      :model_name => "unit",
      :attribute_name => "user_ids",
      :select_title => "Select a new member",
      :options =>  User.all.collect {|u| [u.username, u.id] },
      :selected_options => user_ids}]
  end

  def to_s
    name
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

