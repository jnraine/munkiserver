class Permission < ActiveRecord::Base
  validates :principal_id, :presence => true
  validates :privilege_id, :presence => true
  # validates :the_whole_record, :distinct_permission => true # do this later
  
  belongs_to :principal, :polymorphic => true
  belongs_to :unit
  belongs_to :privilege
end
