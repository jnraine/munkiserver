class AddLastIpToComputer < ActiveRecord::Migration
  def change
    add_column :computers, :last_ip, :string, default: ""
  end
end
