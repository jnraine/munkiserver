class Assignment < ActiveRecord::Base

belongs_to :user
belongs_to :role
belongs_to :unit

validates_presence_of :user_id
validates_presence_of :role_id
validates_presence_of :unit_id

end
