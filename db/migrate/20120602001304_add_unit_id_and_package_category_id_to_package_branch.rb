class AddUnitIdAndPackageCategoryIdToPackageBranch < ActiveRecord::Migration
  def change
    add_column :package_branches, :unit_id, :integer
    add_column :package_branches, :package_category_id, :integer
  end
end
