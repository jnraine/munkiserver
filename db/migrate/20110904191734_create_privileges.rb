class CreatePrivileges < ActiveRecord::Migration
  def self.up
    create_table :privileges do |t|
      t.string :name
      t.text :description
      t.boolean :unit_specific, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :privileges
  end
end
