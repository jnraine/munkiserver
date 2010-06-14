class CreateVersionTrackers < ActiveRecord::Migration
  def self.up
    create_table :version_trackers do |t|
      t.integer :package_branch_id
      t.integer :web_id
      t.string :version
      t.string :download_url

      t.timestamps
    end
  end

  def self.down
    drop_table :version_trackers
  end
end
