require 'test_helper'

class SpPrintersTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: sp_printers
#
#  id                   :integer         not null, primary key
#  name                 :string(255)
#  cupsversion          :string(255)
#  default              :string(255)
#  driverversion        :string(255)
#  fax                  :string(255)
#  ppd                  :string(255)
#  ppdfileversion       :string(255)
#  printserver          :string(255)
#  psversion            :string(255)
#  scanner              :string(255)
#  scanner_uuid         :string(255)
#  scannerappbundlepath :string(255)
#  scannerapppath       :string(255)
#  status               :string(255)
#  uri                  :string(255)
#  system_profile_id    :integer
#  created_at           :datetime
#  updated_at           :datetime
#

