class BundleItem < ActiveRecord::Base
  belongs_to :bundle
  belongs_to :manifest, :polymorphic => true
end

# == Schema Information
#
# Table name: bundle_items
#
#  id            :integer         not null, primary key
#  manifest_id   :integer
#  manifest_type :string(255)
#  bundle_id     :integer
#  created_at    :datetime
#  updated_at    :datetime
#

