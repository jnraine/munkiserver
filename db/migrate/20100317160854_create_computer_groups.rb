class CreateComputerGroups < ActiveRecord::Migration
  def self.up
    create_table :computer_groups do |t|
      t.string :name
      t.text :description
      t.integer :unit_id
      t.integer :environment_id
      # To allow for raw text to be added
      t.text :raw_tags
      t.text :raw_mode
      t.timestamps
    end
  end

  def self.down
    drop_table :computer_groups
  end
end
