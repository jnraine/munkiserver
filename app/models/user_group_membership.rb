class UserGroupMembership < ActiveRecord::Base
  validates :user_id, :presence => true
  validates :user_group_id, :presence => true
end
