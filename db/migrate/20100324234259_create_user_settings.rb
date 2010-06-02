class CreateUserSettings < ActiveRecord::Migration
  def self.up
    create_table :user_settings do |t|
      t.boolean :receive_email_notifications
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :user_settings
  end
end
