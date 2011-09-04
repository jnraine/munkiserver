class UserGroupMembership < ActiveRecord::Base
  validates :user_id, :presence => true
  validates :user_group_id, :presence => true
  
  belongs_to :user
  belongs_to :user_group
end
