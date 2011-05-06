require 'test_helper'

class BundleItemTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: bundle_items
#
#  id            :integer         not null, primary key
#  manifest_id   :integer
#  manifest_type :string(255)
#  bundle_id     :integer
#  created_at    :datetime
#  updated_at    :datetime
#

