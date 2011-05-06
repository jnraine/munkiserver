require 'test_helper'

class PackageCategoryTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: package_categories
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  description :text
#  icon_id     :integer
#  created_at  :datetime
#  updated_at  :datetime
#

