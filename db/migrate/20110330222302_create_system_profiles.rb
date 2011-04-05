class CreateSystemProfiles < ActiveRecord::Migration
  def self.up
    create_table :system_profiles do |t|
      t.integer :computer_id
      
      # SPHardwareDataType (Hardware Overview)
      t.string :cpu_type
      t.string :current_processor_speed
      t.string :l2_cache_core
      t.string :l3_cache
      t.string :machine_model
      t.string :machine_name
      t.string :number_processors
      t.string :physical_memory
      t.string :platform_uuid
      t.string :serial_number

      # SPSoftwareDataType (OS Overview)
      t.string :os_64bit_kernel_and_kexts
      t.string :boot_volume
      t.string :kernel_version
      t.string :local_host_name
      t.string :os_version
      t.string :uptime
      t.string :user_name
      
      t.timestamps
    end
  end

  def self.down
    drop_table :system_profiles
  end
end
