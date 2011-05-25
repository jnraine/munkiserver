class AddPrePostUninstallScriptsToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :preuninstall_script, :text
    add_column :packages, :postuninstall_script, :text
  end

  def self.down
    remove_column :packages, :preuninstall_script, :text
    remove_column :packages, :postuninstall_script, :text
  end
end
