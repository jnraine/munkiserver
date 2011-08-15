class AddForceInstallAfterDateToPackage < ActiveRecord::Migration
  def self.up
    add_column :packages, :force_install_after_date, :datetime
  end

  def self.down
    remove_column :packages, :force_install_after_date
  end
end