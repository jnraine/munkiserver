class AddMoreEntriesToWarranties < ActiveRecord::Migration
  def self.up
    add_column :warranties, :serial_number,     :string
    add_column :warranties, :image_url,         :string
    add_column :warranties, :registered,        :boolean
    add_column :warranties, :specs_url,         :string
    add_column :warranties, :hw_support_url,    :string
    add_column :warranties, :forum_url,         :string
    add_column :warranties, :phone_support_url, :string
    add_column :warranties, :hw_support_coverage,     :string
    add_column :warranties, :hw_coverage_description, :string
    add_column :warranties, :product_type,            :string
    
  end

  def self.down
    remove_column :warranties, :serial_number
    remove_column :warranties, :image_url     
    remove_column :warranties, :registered 
    remove_column :warranties, :specs_url
    remove_column :warranties, :hw_support_url
    remove_column :warranties, :forum_url
    remove_column :warranties, :phone_support_url
    
    remove_column :warranties, :hw_end_date
    remove_column :warranties, :hw_support_coverage
    remove_column :warranties, :hw_coverage_description
    remove_column :warranties, :product_type 
  end
end