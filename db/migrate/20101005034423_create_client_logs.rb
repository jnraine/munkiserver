class CreateClientLogs < ActiveRecord::Migration
  def self.up
    create_table :client_logs do |t|
      t.integer :computer_id
      t.text :managed_software_update_log
      t.text :errors_log
      t.text :installs_log
      t.timestamps
    end
  end

  def self.down
    drop_table :client_logs
  end
end
