class AddShortNameToUnit < ActiveRecord::Migration
  def self.up
    add_column :units, :shortname, :string
  end

  def self.down
    remove_column :units, :shortname , :string
  end
end
