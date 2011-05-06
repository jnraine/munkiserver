require 'test_helper'

class MembershipTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: memberships
#
#  id                     :integer         not null, primary key
#  unit_id                :integer
#  user_id                :integer
#  create_computer        :boolean         default(TRUE)
#  read_computer          :boolean         default(TRUE)
#  edit_computer          :boolean         default(TRUE)
#  destroy_computer       :boolean         default(TRUE)
#  create_bundle          :boolean         default(TRUE)
#  read_bundle            :boolean         default(TRUE)
#  edit_bundle            :boolean         default(TRUE)
#  destroy_bundle         :boolean         default(TRUE)
#  create_computer_group  :boolean         default(TRUE)
#  read_computer_group    :boolean         default(TRUE)
#  edit_computer_group    :boolean         default(TRUE)
#  destroy_computer_group :boolean         default(TRUE)
#  create_package         :boolean         default(TRUE)
#  read_package           :boolean         default(TRUE)
#  edit_package           :boolean         default(TRUE)
#  destroy_package        :boolean         default(TRUE)
#  edit_unit              :boolean         default(FALSE)
#  created_at             :datetime
#  updated_at             :datetime
#

