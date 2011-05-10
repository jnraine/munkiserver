class AddInstallScriptsToPackages < ActiveRecord::Migration
  def self.up
     add_column :packages, :preinstall_script, :text
     add_column :packages, :postinstall_script, :text
  end

  def self.down
    remove_column :packages, :preinstall_script
    remove_column :packages, :postinstall_script
  end
end
