class UnitSetting < ActiveRecord::Base
  belongs_to :unit
  
  # Unit setting defaults
  # New records initialized with the following values
  DEFAULTS = {:notify_users => true,
              :regular_events => {:new_package_added => true}.to_yaml,
              :warning_events => {:something_might_break => true}.to_yaml,
              :error_events => {:invalid_plist => true}.to_yaml,
              :version_tracking => true }
  
  attr_is_hash :regular_events
  attr_is_hash :warning_events
  attr_is_hash :error_events
  
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
# Table name: unit_settings
#
#  id               :integer         not null, primary key
#  notify_users     :boolean
#  unit_email       :string(255)
#  regular_events   :text
#  warning_events   :text
#  error_events     :text
#  unit_id          :integer
#  version_tracking :boolean
#  created_at       :datetime
#  updated_at       :datetime
#

