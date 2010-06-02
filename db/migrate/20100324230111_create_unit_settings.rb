class CreateUnitSettings < ActiveRecord::Migration
  def self.up
    create_table :unit_settings do |t|
      t.boolean :notify_users
      t.string :unit_email
      t.text :regular_events
      t.text :warning_events
      t.text :error_events
      t.integer :unit_id
      t.boolean :version_tracking

      t.timestamps
    end
  end

  def self.down
    drop_table :unit_settings
  end
end
