class Role < ActiveRecord::Base
  
  has_many :assignments
  has_many :users, :through => :assignments 
  
  validates_presence_of :name
  validates_uniqueness_of :name, :message => "must be unique"
  
  def self.admin
    Role.find_by_name("Admin")
  end
  
  def self.super_user
    Role.find_by_name("Super User")
  end
  
  def self.user
    Role.find_by_name("User")
  end
  
  def to_sym
    name.downcase.tr(' ', '_').to_sym
  end
  
  def to_s
    name
  end
end
