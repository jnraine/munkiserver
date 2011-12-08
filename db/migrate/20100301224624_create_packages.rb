class CreatePackages < ActiveRecord::Migration
  def self.up
    create_table :packages do |t|
      # Basics
      t.string :version
      t.integer :package_branch_id
      t.integer :unit_id
      t.integer :environment_id
      t.integer :package_category_id
      t.text :receipts
      t.text :description
      t.integer :icon_id
      t.string :filename
      
      
      # Optional
      t.text :supported_architectures
      t.text :minimum_os_version
      t.text :maximum_os_version
      t.text :installs
      t.string :RestartAction
      t.string :package_path
      t.boolean :autoremove, :default => false
      t.boolean :shared, :default => false
      t.string :version_tracker_version
      
      # Install info
      t.string :installer_type
      t.integer :installed_size
      t.integer :installer_item_size
      t.string :installer_item_location
      t.text :installer_choices_xml
      t.boolean :use_installer_choices, :default => false

      # Uninstall info
      t.string :uninstall_method
      t.string :uninstaller_item_location
      t.integer :uninstaller_item_size
      t.boolean :uninstallable, :default => true      

      # Dependancy
      # t.text :requires
      # t.text :update_for
      
      # For yet-to-be-made munki repo
      t.string :installer_item_checksum
      
      # To allow for raw text to be added
      t.text :raw_tags
      t.integer :raw_mode_id, :default => 0
      
      t.timestamps
    end
  end

  def self.down
    drop_table :packages
  end
end
