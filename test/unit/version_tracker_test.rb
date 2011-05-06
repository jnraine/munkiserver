require 'test_helper'

class VersionTrackerTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: version_trackers
#
#  id                :integer         not null, primary key
#  package_branch_id :integer
#  web_id            :integer
#  version           :string(255)
#  download_url      :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#

