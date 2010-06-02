class CreateUpdateForItems < ActiveRecord::Migration
  def self.up
    create_table :update_for_items do |t|
      t.integer :package_branch_id
      t.integer :package_id
      t.integer :manifest_id
      t.string :manifest_type

      t.timestamps
    end
  end

  def self.down
    drop_table :update_for_items
  end
end
