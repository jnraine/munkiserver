class RemoveMembershipsAndSuperUserFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :super_user
    drop_table :memberships
  end

  def self.down
    add_column :users, :super_user, :boolean, :default => true
    create_table :memberships do |t|
      t.integer :unit_id
      t.integer :user_id
      
      # ACLs
      t.boolean :create_computer, :default => true
      t.boolean :read_computer, :default => true
      t.boolean :edit_computer, :default => true
      t.boolean :destroy_computer, :default => true
      
      t.boolean :create_bundle, :default => true
      t.boolean :read_bundle, :default => true
      t.boolean :edit_bundle, :default => true
      t.boolean :destroy_bundle, :default => true
      
      t.boolean :create_computer_group, :default => true
      t.boolean :read_computer_group, :default => true
      t.boolean :edit_computer_group, :default => true
      t.boolean :destroy_computer_group, :default => true
      
      t.boolean :create_package, :default => true
      t.boolean :read_package, :default => true
      t.boolean :edit_package, :default => true
      t.boolean :destroy_package, :default => true
      
      t.boolean :edit_unit, :default => false

      t.timestamps
    end
  end
end