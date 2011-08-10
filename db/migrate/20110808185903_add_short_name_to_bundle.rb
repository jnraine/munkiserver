class AddShortNameToBundle < ActiveRecord::Migration
  def self.up
    add_column :bundles, :shortname, :string
  end

  def self.down
    remove_column :bundles, :shortname , :string
  end
end
