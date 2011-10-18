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
  
  def self.check_principal_existence(model,id)
    unless model.constantize.where(:id => id).first
      raise ArgumentError.new("The provided principal (#{model}, #{id}) is not valid!")
    end
  end
  
  def self.save_permission_set(p_field_hash)
    results = {:saved_records => [], :unsaved_records => [], :destroyed_records => [], :total => 0, :failed => 0, :new_records => 0}
    p_field_hash.values.each do |p_fields|
      p = nil
      if p_fields[:retain].present?
        # Retain records
        if p_fields[:id].present?
          # Retrieve saved record
          p = Permission.find(p_fields[:id])
        else
          # Save records that are new
          p = Permission.new(:principal_id => p_fields[:principal_id], :principal_type => p_fields[:principal_type].camelcase, :privilege_id => p_fields[:privilege_id], :unit_id => p_fields[:unit_id])
          if p.save
            results[:new_records] += 1
          else
            results[:failed] += 1
          end
        end
        results[:saved_records] << p
      elsif p_fields[:id].present?
        # Delete saved permissions that aren't set to retain
        p = Permission.find(p_fields[:id])
        p.destroy
        results[:destroyed_records] << p
      else
        # Don't do anything with unsaved records - let them pass away
        results[:unsaved_records] << p_fields
      end
      results[:total] += 1
    end
    results
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
    
    check_principal_existence(principal_type,principal_id)
    
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
  
  # Instatiates a new object, belonging to unit.  Caches for future calls.
  def self.new_for_can(unit)
    raise ArgumentError.new("Unit passed to new_for_can is nil") if unit.nil?
    @new_for_can ||= []
    @new_for_can[unit.id] ||= self.new(:unit => unit)
  end
end
