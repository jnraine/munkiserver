class CreateAssignments < ActiveRecord::Migration
  def self.up
    create_table :assignments do |t|
      t.integer :user_id
      t.integer :role_id
      
      # Maybe someday we could like a role to a specific unit?
      t.integer :unit_id

      t.timestamps
    end
  end

  def self.down
    drop_table :assignments
  end
end
