class AddConfigurationToItems < ActiveRecord::Migration
  def self.up
    add_column :computers, :configuration_id, :integer
    add_column :computer_groups, :configuration_id, :integer
    add_column :units, :configuration_id, :integer
  end

  def self.down
    remove_column :computers, :configuration_id
    remove_column :computer_groups, :configuration_id
    remove_column :units, :configuration_id    
  end
end
