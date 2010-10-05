class CreateClientLogs < ActiveRecord::Migration
  def self.up
    create_table :client_logs do |t|
      t.integer :computer_id
      t.text :details
      t.timestamps
    end
  end

  def self.down
    drop_table :client_logs
  end
end
