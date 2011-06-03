class AddUnattendedUninstallToPackages < ActiveRecord::Migration
  def self.up
      add_column :packages, :unattended_uninstall, :boolean, :default => false
  end

  def self.down
      remove_column :packages, :unattended_uninstall
  end
end
