require 'digest/sha1'

class User < ActiveRecord::Base
  validates_length_of :username, :within => 3..40
  validates_length_of :password, :within => 5..40, :if => :password_changed?
  validates_presence_of :username, :email, :salt
  validates_presence_of :password, :password_confirmation, :if => :password_changed?
  validates_uniqueness_of :username, :email
  validates_confirmation_of :password
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "Invalid email"
  
  attr_protected :id, :salt
  attr_accessor :password

  has_many :memberships
  has_many :units, :through => :memberships
  
  has_one :settings, :dependent => :destroy, :class_name => "UserSetting", :autosave => true

  before_save :check_settings

  # Generate a random string consisting of strings and digits
  # with a length of up to len characters
  def self.random_string(len)
    c = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    s = ""
    1.upto(len) { |i| s << c[rand(c.size-1)] }
    return s
  end
  
  # Combine the pass and salt and return an encrypted string
  def self.encrypt(pass, salt)
    Digest::SHA1.hexdigest(pass + salt)
  end
  
  # Did the password change since our last save?
  def password_changed?
    hashed_password_changed?
  end
  
  def password=(pass)
    @password = pass
    self.salt = User.random_string(10) unless self.salt?
    self.hashed_password = User.encrypt(@password, self.salt)
  end
  
  def self.authenticate(username, pass)
    u = find_by_username(username)
    return u if (u != nil) and (User.encrypt(pass, u.salt) == u.hashed_password)
  end
  
  def member_of(unit)
    unit_ids.include?(unit.id)
  end
  
  # Returns membership that self and unit share
  def membership(unit)
    unit.membership(self)
  end
  
  # Returns true if user is super user
  def super_user?
    super_user
  end
  
  # A to string method
  def to_s
    username
  end
  
  # Checks if a unit has a settings association
  # and creates on if it doesn't
  def check_settings
    init_settings if settings.nil?
  end
  
  # Initialize default settings
  def init_settings
    us = UserSetting.new
    self.settings = us
  end
  
  # Roles used by this application.  This is required by
  # the declarative_authorization gem
  def role_symbols
    [:admin,:developer,:support_person]
  end
end