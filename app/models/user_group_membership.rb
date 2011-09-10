class UserGroupMembership < ActiveRecord::Base
  validates :principal_id, :presence => true
  validates :principal_type, :presence => true
  validates :user_group_id, :presence => true
  
  belongs_to :principal, :polymorphic => :true
  belongs_to :user_group
end
