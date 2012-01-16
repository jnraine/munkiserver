class CreateComputers < ActiveRecord::Migration
  def self.up
    create_table :computers do |t|
      t.string :mac_address
      t.string :name
      t.text :system_profiler_info
      t.text :description
      t.integer :computer_model_id
      t.integer :computer_group_id
      t.integer :unit_id
      t.integer :environment_id
      # To allow for raw text to be added
      t.text :raw_tags
      t.text :raw_mode
      t.timestamps
    end
  end

  def self.down
    drop_table :computers
  end
end
