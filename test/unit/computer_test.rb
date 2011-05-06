require 'test_helper'

class ComputerTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: computers
#
#  id                   :integer         not null, primary key
#  mac_address          :string(255)
#  name                 :string(255)
#  system_profiler_info :text
#  description          :text
#  computer_model_id    :integer
#  computer_group_id    :integer
#  unit_id              :integer
#  environment_id       :integer
#  raw_tags             :text
#  raw_mode             :text            default("f")
#  created_at           :datetime
#  updated_at           :datetime
#

