class CreateIcons < ActiveRecord::Migration
  def self.up
    create_table :icons do |t|
      t.string :filename
      t.string :content_type
      t.string :thumbnail
      t.integer :parent_id
      t.integer :size
      t.integer :width
      t.integer :height

      t.timestamps
    end
  end

  def self.down
    drop_table :icons
  end
end
