require 'test_helper'

class ComputerGroupTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: computer_groups
#
#  id             :integer         not null, primary key
#  name           :string(255)
#  description    :text
#  unit_id        :integer
#  environment_id :integer
#  raw_tags       :text
#  raw_mode       :text            default("f")
#  created_at     :datetime
#  updated_at     :datetime
#

