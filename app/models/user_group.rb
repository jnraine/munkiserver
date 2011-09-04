class UserGroup < ActiveRecord::Base
  validates :name, :presence => true
  validates :unit_id, :presence => true
  
  has_many :permissions, :as => principal
  has_many :privileges, :through => :permissions
  has_many :units, :through => :permissions
  has_many :user_group_memberships
  has_many :users, :through => :user_group_memberships
  belongs_to :unit
end
