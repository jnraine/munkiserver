class AddUnitIdToPackageBranch < ActiveRecord::Migration
  def change
    add_column :package_branches, :unit_id, :integer
  end
end
