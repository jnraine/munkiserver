class AddIconIdToVersionTrackers < ActiveRecord::Migration
  def self.up
    add_column :version_trackers, :icon_id, :integer
  end

  def self.down
    remove_column :version_trackers, :icon_id, :integer
  end
end
