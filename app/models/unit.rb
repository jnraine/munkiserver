class Unit < ActiveRecord::Base
  has_many :computers, :dependent => :destroy
  has_many :computer_groups, :dependent => :destroy
  has_many :bundles, :dependent => :destroy
  has_many :packages, :dependent => :destroy
  has_many :principals, :through => :permissions
  has_many :package_branches, :dependent => :destroy
  
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

  def users_who_can_read(controller_name)
    principals = Permission.where(:privilege_id => Privilege.find_by_name("read_#{controller_name}"), :unit_id => id).map(&:principal)
    users = []
    principals.each do |principal|
      if principal.is_a? User
        users << principal
      elsif principal.is_a? UserGroup
        users + principal.users
      else
        raise UserGroupException.new("While retrieving users who can read #{controller_name} from a unit (#{self}), found a principal that was not a User or UserGroup record!")
      end
    end
    users.uniq {|e| e.id }
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

