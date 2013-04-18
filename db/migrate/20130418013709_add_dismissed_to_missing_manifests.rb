class AddDismissedToMissingManifests < ActiveRecord::Migration
  def change
    add_column :missing_manifests, :dismissed, :boolean, :default => false
  end
end
