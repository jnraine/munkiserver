class Notification < ActiveRecord::Base
  belongs_to :notified, :polymorphic => true
end