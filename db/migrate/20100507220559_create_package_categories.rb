class CreatePackageCategories < ActiveRecord::Migration
  def self.up
    create_table :package_categories do |t|
      t.string :name
      t.text :description
      t.integer :icon_id
      t.timestamps
    end
  end

  def self.down
    drop_table :package_categories
  end
end
