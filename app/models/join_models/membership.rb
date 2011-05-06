class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :unit
  
  # Returns a list of ACLs columns in the DB
  def self.acls
    # Stores attributes that do not represent an ACL
    non_acl_attr = [:id,:unit_id,:updated_at,:user_id,:created_at]
    column_names.collect(&:to_sym).delete_if {|k,v| non_acl_attr.include?(k) }
  end
  
  # Return hash of acl attributes (as keys) and their values
  def acls
    h = {}
    Membership.acls.each do |acl|
      h[acl] = read_attribute(acl)
    end
    h
  end
end

# == Schema Information
#
# Table name: memberships
#
#  id                     :integer         not null, primary key
#  unit_id                :integer
#  user_id                :integer
#  create_computer        :boolean         default(TRUE)
#  read_computer          :boolean         default(TRUE)
#  edit_computer          :boolean         default(TRUE)
#  destroy_computer       :boolean         default(TRUE)
#  create_bundle          :boolean         default(TRUE)
#  read_bundle            :boolean         default(TRUE)
#  edit_bundle            :boolean         default(TRUE)
#  destroy_bundle         :boolean         default(TRUE)
#  create_computer_group  :boolean         default(TRUE)
#  read_computer_group    :boolean         default(TRUE)
#  edit_computer_group    :boolean         default(TRUE)
#  destroy_computer_group :boolean         default(TRUE)
#  create_package         :boolean         default(TRUE)
#  read_package           :boolean         default(TRUE)
#  edit_package           :boolean         default(TRUE)
#  destroy_package        :boolean         default(TRUE)
#  edit_unit              :boolean         default(FALSE)
#  created_at             :datetime
#  updated_at             :datetime
#

