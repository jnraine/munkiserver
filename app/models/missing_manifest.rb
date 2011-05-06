class MissingManifest < ActiveRecord::Base
end

# == Schema Information
#
# Table name: missing_manifests
#
#  id            :integer         not null, primary key
#  manifest_type :string(255)
#  identifier    :string(255)
#  request_ip    :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

