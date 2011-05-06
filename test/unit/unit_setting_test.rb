require 'test_helper'

class UnitSettingTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
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

