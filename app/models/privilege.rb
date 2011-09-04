class Privilege < ActiveRecord::Base
  validates :name, :presence => true
  
  has_many :permissions
  has_many :units, :through => :permissions
  has_many :principals, :through => :permissions
end
