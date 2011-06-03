class BundleItem < ActiveRecord::Base
  belongs_to :bundle
  belongs_to :manifest, :polymorphic => true
end

