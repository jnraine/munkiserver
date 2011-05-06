require 'test_helper'

class UserSettingTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
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

