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

