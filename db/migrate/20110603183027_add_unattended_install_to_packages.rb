class AddUnattendedInstallToPackages < ActiveRecord::Migration
  def self.up
      add_column :packages, :unattended_install, :boolean, :default => false
  end

  def self.down
      remove_column :packages, :unattended_install
  end
end
