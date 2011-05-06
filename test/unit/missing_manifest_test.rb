require 'test_helper'

class MissingManifestTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: missing_manifests
#
#  id            :integer         not null, primary key
#  manifest_type :string(255)
#  identifier    :string(255)
#  request_ip    :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

