class AddShortNameToComputer < ActiveRecord::Migration
  def self.up
    add_column :computers, :shortname, :string
  end

  def self.down
    remove_column :computers, :shortname , :string
  end
end
