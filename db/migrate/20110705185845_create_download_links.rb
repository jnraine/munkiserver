class CreateDownloadLinks < ActiveRecord::Migration
  def self.up
    create_table :download_links do |t|
      t.string :text
      t.string :url
      t.string :caption
      t.integer :version_tracker_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :download_links
  end
end
