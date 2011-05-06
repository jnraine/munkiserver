require 'test_helper'

class ClientLogTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: client_logs
#
#  id                          :integer         not null, primary key
#  computer_id                 :integer
#  managed_software_update_log :text
#  errors_log                  :text
#  installs_log                :text
#  created_at                  :datetime
#  updated_at                  :datetime
#

