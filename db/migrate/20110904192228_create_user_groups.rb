class CreateUserGroups < ActiveRecord::Migration
  def self.up
    create_table :user_groups do |t|
      t.string :name
      t.text :description
      t.integer :unit_id
      t.timestamps
    end
  end

  def self.down
    drop_table :user_groups
  end
end
