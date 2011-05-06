require 'test_helper'

class ManagedInstallReportTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: managed_install_reports
#
#  id                      :integer         not null, primary key
#  ip                      :string(255)
#  manifest_name           :string(255)
#  run_type                :string(255)
#  console_user            :string(255)
#  managed_install_version :string(255)
#  start_time              :datetime
#  end_time                :datetime
#  available_disk_space    :integer
#  computer_id             :integer
#  munki_errors            :text
#  munki_warnings          :text
#  install_results         :text
#  installed_items         :text
#  items_to_install        :text
#  items_to_remove         :text
#  machine_info            :text
#  managed_installs        :text
#  problem_installs        :text
#  removal_results         :text
#  removed_items           :text
#  managed_installs_list   :text
#  managed_uninstalls_list :text
#  managed_updates_list    :text
#  created_at              :datetime
#  updated_at              :datetime
#

