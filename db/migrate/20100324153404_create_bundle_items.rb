class CreateBundleItems < ActiveRecord::Migration
  def self.up
    create_table :bundle_items do |t|
      t.integer :manifest_id
      t.string :manifest_type
      t.integer :bundle_id

      t.timestamps
    end
  end

  def self.down
    drop_table :bundle_items
  end
end
