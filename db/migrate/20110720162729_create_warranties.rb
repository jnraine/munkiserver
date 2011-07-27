class CreateWarranties < ActiveRecord::Migration
  def self.up
    create_table :warranties do |t|
      t.string :serial_number, :default => ""
      t.string :product_description, :default => ""
      t.string :product_type, :default => ""
      
      t.datetime :purchase_date
      t.datetime :hw_coverage_end_date
      t.datetime :phone_coverage_end_date

      t.boolean :registered
      t.boolean :hw_coverage_expired
      t.boolean :phone_coverage_expired
      t.boolean :app_registered
      t.boolean :app_eligible

      t.string :specs_url, :default => ""
      t.string :hw_support_url, :default => ""
      t.string :forum_url, :default => ""
      t.string :phone_support_url, :default => ""
      
      t.integer :computer_id
      t.timestamps
    end
  end

  def self.down
    drop_table :warranties
  end
end
