class CreateManagedInstallReports < ActiveRecord::Migration
  def self.up
    create_table :managed_install_reports do |t|
      t.string :ip
      t.string :manifest_name
      t.string :run_type
      t.string :console_user
      t.string :managed_install_version
      
      t.timestamp :start_time
      t.timestamp :end_time

      t.integer :available_disk_space
      t.integer :computer_id

      t.text :munki_errors
      t.text :munki_warnings
      t.text :install_results
      t.text :installed_items
      t.text :items_to_install
      t.text :items_to_remove
      t.text :machine_info
      t.text :managed_installs
      t.text :problem_installs
      t.text :removal_results
      t.text :removed_items
      t.text :managed_installs_list
      t.text :managed_uninstalls_list
      t.text :managed_updates_list

      t.timestamps
    end
  end

  def self.down
    drop_table :managed_install_reports
  end
end
