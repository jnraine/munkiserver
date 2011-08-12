class AddDescriptionToVersionTrackers < ActiveRecord::Migration
  def self.up
    add_column :version_trackers, :description, :text
  end

  def self.down
    remove_column :version_trackers, :description, :text
  end
end
