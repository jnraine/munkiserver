class Permission < ActiveRecord::Base
  validates :principal_id, :presence => true
  validates :privilege_id, :presence => true
  # validates :the_whole_record, :distinct_permission => true # do this later
  
  belongs_to :principal, :polymorphic => true
  belongs_to :unit
  belongs_to :privilege
  
  # Group by the privilege name suffix.  Return a hash, keyed by the privilege
  # group string.
  def self.retrieve_in_privilege_groups(opts = {})
    grouped_permissions = retrieve(opts).group_by do |permission|
      permission.privilege.action_target
    end
    Hash[grouped_permissions.sort]
  end
  
  # Return all records pertaining to a given principal_pointer and unit_id.  If unit
  # ID is nil, retrieve non-unit-specific permission records.  principal_pointer is
  # not an integer, but instead a string in this format: "#{principal_type}-#{principal_id}",
  # where record_id refers to an integer record in the database.
  def self.retrieve(opts = {})
    defaults = {:unit_id => nil, :principal_pointer => nil}
    opts = defaults.merge(opts)
    unit = Unit.where(:id => opts[:unit_id]).first
    principal_type = opts[:principal_pointer].match(/(.+)-(.+)/)[1]
    principal_id = opts[:principal_pointer].match(/(.+)-(.+)/)[2]
    
    privilege_ids = nil
    if unit
      # Get unit-specific permissions records related to principal_id and unit_id
      privilege_ids = Privilege.unit_specific.map(&:id)
    else
      # Get non-unit-specific permission records related to principal_id
      privilege_ids = Privilege.unit_nonspecific.map(&:id)
    end
    find_or_instantiate(:privilege_ids => privilege_ids, :principal_id => principal_id, :principal_type => principal_type, :unit_id => opts[:unit_id])
  end
  
  # Find a permission matching the passed paramters, or instantiate a new record
  # with those parameters.  Returns the permission record.  Accepts the following
  # parameters:
  # => :privilege_ids (mandatory)
  # => :principal_id (mandatory)
  # => :principal_type (mandatory)
  # => :unit_id
  def self.find_or_instantiate(params = {})
    raise ArgumentError.new("privilege_ids must be an array") unless params[:privilege_ids].is_a? Array
    perms = []
    params[:privilege_ids].each do |privilege_id|
      perm = Permission.where(:privilege_id => privilege_id, :principal_id => params[:principal_id], :principal_type => params[:principal_type], :unit_id => params[:unit_id]).includes(:privilege).limit(1).first
      perm ||= Permission.new(:privilege_id => privilege_id, :principal_id => params[:principal_id], :principal_type => params[:principal_type], :unit_id => params[:unit_id])
      perms << perm
      perm = nil
    end
    perms
  end
end
