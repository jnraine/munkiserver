class AddHostnameToMissingManifests < ActiveRecord::Migration
  def self.up
    add_column :missing_manifests, :hostname, :string
  end

  def self.down
    remove_column :missing_manifests, :hostname, :string
  end
end
