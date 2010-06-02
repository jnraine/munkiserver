class VersionTracker < ActiveRecord::Base
  belongs_to :package_branch
end
