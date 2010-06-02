class CreateComputerModels < ActiveRecord::Migration
  def self.up
    create_table :computer_models do |t|
      t.string :name
      t.string :identifier
      t.integer :icon_id
      t.timestamps
    end
  end

  def self.down
    drop_table :computer_models
  end
end
