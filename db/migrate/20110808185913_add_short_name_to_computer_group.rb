class AddShortNameToComputerGroup < ActiveRecord::Migration
  def self.up
    add_column :computer_groups, :shortname, :string
  end

  def self.down
    remove_column :computer_groups, :shortname , :string
  end
end
