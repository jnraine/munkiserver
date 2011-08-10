require 'digest/sha1'

class User < ActiveRecord::Base
  
  @@password_constraints = {
    :pass_len => "must be between 5-24 characters",
    :pass_nums => "must contain at least one number",
    :pass_upper => "must contain at least one upper case character",
    :pass_lower => "must contain at least one lower case character"}

  validates_length_of :username, :within => 3..40
  # ensure password has enough letters, but not too many
  validates_length_of :password, :in => 5..24, :if => :password_changed?,
    :message => @@password_constraints[:pass_len]
  # ensure password contains at least one number
  # validates_format_of :password, :with => /[0-9]/, :if => :password_changed?,
  #   :message => @@password_constraints[:pass_nums]
  # ensure password contains at least one upper case  
  # validates_format_of :password, :with => /[A-Z]/, :if => :password_changed?,
  #   :message => @@password_constraints[:pass_upper]
  # ensure password contains at least one lower case  
  # validates_format_of :password, :with => /[a-z]/, :if => :password_changed?,
  #   :message => @@password_constraints[:pass_lower]
  validates_presence_of :username, :email
  validates_presence_of :salt, :message => "is missing. New users require a password."
  validates_presence_of :password, :password_confirmation, :if => :password_changed?
  validates_uniqueness_of :username, :email
  validates_confirmation_of :password, :if => :password_changed?
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "address doesn't look valid"
  
  attr_protected :id, :salt
  attr_accessor :password

  has_many :assignments, :dependent => :destroy
  has_many :units, :through => :assignments
  has_many :roles, :through => :assignments
  
  has_one :settings, :dependent => :destroy, :class_name => "UserSetting", :autosave => true

  before_save :check_settings
  
  def self.password_constraints
    @@password_constraints.values
  end
  
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
    unless @password.blank?  
      self.salt = User.random_string(10) unless self.salt?
      self.hashed_password = User.encrypt(@password, self.salt)
    end
  end
  
  def self.authenticate(username, pass)
    u = find_by_username(username)
    return u if (u != nil) and (User.encrypt(pass, u.salt) == u.hashed_password)
  end
  
  def member_of(unit)
    unit_ids.include?(unit.id)
  end
  
  # Returns membership that self and unit share
  # def membership(unit)
  #   unit.`membership`(self)
  # end
  
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
  
  # over write default to_param use name in the routing instead of id
  def to_param
    username
  end
end
