class UserSetting < ActiveRecord::Base
  belongs_to :user
  
  DEFAULTS = {:receive_email_notifications => true}
  
  # Sets up defaults
  def initialize
    super
    if new_record?
      self.update_attributes(DEFAULTS)
    end
  end
end

# == Schema Information
#
# Table name: user_settings
#
#  id                          :integer         not null, primary key
#  receive_email_notifications :boolean
#  user_id                     :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#

