class CreatePackageBranches < ActiveRecord::Migration
  def self.up
    create_table :package_branches do |t|
      t.string :name
      t.string :display_name
      # t.string :version_tracker_web_id # This refers to the ID on versiontracker.com NOT the version tracker object associated to it
      t.timestamps
    end
  end

  def self.down
    drop_table :package_branches
  end
end
