class CreateSpPrinter < ActiveRecord::Migration
  def self.up
    create_table :sp_printers do |t|
      t.string :name
      t.string :cupsversion
      t.string :default
      t.string :driverversion
      t.string :fax
      t.string :ppd
      t.string :ppdfileversion
      t.string :printserver
      t.string :psversion
      t.string :scanner
      t.string :scanner_uuid
      t.string :scannerappbundlepath
      t.string :scannerapppath
      t.string :status
      t.string :uri
      t.integer :system_profile_id
      t.timestamps
    end
  end

  def self.down
    drop_table :sp_printers
  end
end
