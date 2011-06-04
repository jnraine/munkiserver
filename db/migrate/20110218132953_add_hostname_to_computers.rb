class AddHostnameToComputers < ActiveRecord::Migration
  def self.up
    add_column :computers, :hostname, :string, :default => ""
  end

  def self.down
    remove_column :computers, :hostname
  end
end
