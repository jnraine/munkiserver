class CreateIcons < ActiveRecord::Migration
  def self.up
    create_table :icons do |t|
      t.string :photo_file_name # Original filename
      t.string :photo_content_type # Mime type
      t.integer :photo_file_size # File size in bytes
      t.datetime :photo_updated_at 
      t.timestamps
    end
  end

  def self.down
    drop_table :icons
  end
end
