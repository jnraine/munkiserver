class CreateWarranties < ActiveRecord::Migration
  def self.up
    create_table :warranties do |t|
      t.datetime :purchase_date
      t.datetime :coverage_end_date

      t.boolean :registered
      t.boolean :coverage_expired
      
      t.integer :computer_id
      
      t.string :serial_number, :default => ""
      t.string :image_url, :default => ""
      t.string :product_description, :default => ""
      t.string :specs_url, :default => ""
      t.string :hw_support_url, :default => ""
      t.string :forum_url, :default => ""
      t.string :phone_support_url, :default => ""
      t.string :hw_support_coverage, :default => ""
      t.string :hw_coverage_description, :default => ""
      t.string :product_type, :default => ""

      t.timestamps
    end
  end

  def self.down
    drop_table :warranties
  end
end
