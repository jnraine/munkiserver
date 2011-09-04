class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.integer :principal_id
      t.string :principal_type
      t.integer :unit_id
      t.integer :privilege_id
      t.timestamps
    end
  end

  def self.down
    drop_table :permissions
  end
end
