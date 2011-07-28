class RemoveSuperUserFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :super_user
  end

  def self.down
  end
end