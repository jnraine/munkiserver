class CreateEnvironments < ActiveRecord::Migration
  def self.up
    create_table :environments do |t|
      t.string :name
      t.text :description
      t.text :environment_ids

      t.timestamps
    end
  end

  def self.down
    drop_table :environments
  end
end
