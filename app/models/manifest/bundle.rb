class Bundle < ActiveRecord::Base
  magic_mixin :manifest
end
# == Schema Information
#
# Table name: bundles
#
#  id             :integer         not null, primary key
#  name           :string(255)
#  description    :text
#  unit_id        :integer
#  environment_id :integer
#  raw_tags       :text
#  raw_mode       :text            default("f")
#  created_at     :datetime
#  updated_at     :datetime
#

