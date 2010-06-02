class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :username
      t.string :hashed_password
      t.string :email
      t.string :salt
      t.boolean :super_user, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
