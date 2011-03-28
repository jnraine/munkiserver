class CreateMissingManifests < ActiveRecord::Migration
  def self.up
    create_table :missing_manifests do |t|
      t.string :manifest_type
      t.string :identifier
      t.string :request_ip
      t.timestamps
    end
  end

  def self.down
    drop_table :missing_manifests
  end
end
