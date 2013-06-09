class AddInstallcheckScriptsToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :installcheck_script,   :text
    add_column :packages, :uninstallcheck_script, :text
  end
end
