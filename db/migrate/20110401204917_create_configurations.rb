class CreateConfigurations < ActiveRecord::Migration
  def self.up
    create_table :configurations do |t|
      t.integer :id
      t.string :configuration
      t.boolean :inherit, :default => true

      t.timestamps
    end
  end

  def self.down
    drop_table :configurations
  end
end
