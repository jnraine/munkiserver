class CreateUserGroupMemberships < ActiveRecord::Migration
  def self.up
    create_table :user_group_memberships do |t|
      t.references :principal, :null => false, :polymorphic => true
      t.references :user_group, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :user_group_memberships
  end
end
