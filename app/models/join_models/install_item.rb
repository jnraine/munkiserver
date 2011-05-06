class InstallItem < ActiveRecord::Base
  magic_mixin :item
end

# == Schema Information
#
# Table name: install_items
#
#  id                :integer         not null, primary key
#  package_branch_id :integer
#  package_id        :integer
#  manifest_id       :integer
#  manifest_type     :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#

