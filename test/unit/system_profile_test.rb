require 'test_helper'

class SystemProfileTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
end

# == Schema Information
#
# Table name: system_profiles
#
#  id                        :integer         not null, primary key
#  computer_id               :integer
#  cpu_type                  :string(255)
#  current_processor_speed   :string(255)
#  l2_cache_core             :string(255)
#  l3_cache                  :string(255)
#  machine_model             :string(255)
#  machine_name              :string(255)
#  number_processors         :string(255)
#  physical_memory           :string(255)
#  platform_uuid             :string(255)
#  serial_number             :string(255)
#  os_64bit_kernel_and_kexts :string(255)
#  boot_volume               :string(255)
#  kernel_version            :string(255)
#  local_host_name           :string(255)
#  os_version                :string(255)
#  uptime                    :string(255)
#  user_name                 :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#

