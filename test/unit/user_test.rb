require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: users
#
#  id              :integer         not null, primary key
#  username        :string(255)
#  hashed_password :string(255)
#  email           :string(255)
#  salt            :string(255)
#  super_user      :boolean         default(FALSE)
#  created_at      :datetime
#  updated_at      :datetime
#

