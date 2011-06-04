class AddUninstallScirptsToPackages < ActiveRecord::Migration
  def self.up
      add_column :packages, :uninstall_script, :text
  end

  def self.down
      remove_column :packages, :uninstall_script
  end
end
