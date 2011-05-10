require 'test_helper'

class PackageTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end




# == Schema Information
#
# Table name: packages
#
#  id                        :integer         not null, primary key
#  version                   :string(255)
#  package_branch_id         :integer
#  unit_id                   :integer
#  environment_id            :integer
#  package_category_id       :integer
#  receipts                  :text            default("--- []")
#  description               :text
#  icon_id                   :integer
#  filename                  :string(255)
#  supported_architectures   :text            default("--- []")
#  minimum_os_version        :text
#  maximum_os_version        :text
#  installs                  :text            default("--- []")
#  RestartAction             :string(255)
#  package_path              :string(255)
#  autoremove                :boolean         default(FALSE)
#  shared                    :boolean         default(FALSE)
#  version_tracker_version   :string(255)
#  preinstall_script         :string(255)
#  postinstall_script        :string(255)
#  installer_type            :string(255)
#  installed_size            :integer
#  installer_item_size       :integer
#  installer_item_location   :string(255)
#  installer_choices_xml     :text
#  use_installer_choices     :boolean         default(FALSE)
#  uninstall_method          :string(255)
#  uninstaller_item_location :string(255)
#  uninstaller_item_size     :integer
#  uninstallable             :boolean         default(TRUE)
#  installer_item_checksum   :string(255)
#  raw_tags                  :text            default("--- {}")
#  raw_mode_id               :integer         default(0)
#  created_at                :datetime
#  updated_at                :datetime
#

