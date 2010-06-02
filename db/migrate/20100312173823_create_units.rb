class CreateUnits < ActiveRecord::Migration
  def self.up
    create_table :units do |t|
      t.string :name
      t.text :description
      t.string :key
      t.integer :unit_member_id
      t.integer :unit_member_type          
                                       
      t.timestamps                     
    end                                
  end

  def self.down
    drop_table :units
  end
end
