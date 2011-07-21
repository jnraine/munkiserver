class CreateWarranties < ActiveRecord::Migration
  def self.up
    create_table :warranties do |t|
      t.datetime  :purchase_date
      t.string    :product_description, :default => ""
      t.datetime  :coverage_end_date
      t.boolean   :coverage_expired
      t.integer   :computer_id

      t.timestamps
    end
  end

  def self.down
    drop_table :warranties
  end
end
