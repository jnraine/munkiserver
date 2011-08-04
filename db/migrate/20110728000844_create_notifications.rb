class CreateNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.references :notified, :polymorphic => true
      t.timestamps
    end
  end

  def self.down
    drop_table :notifications
  end
end
