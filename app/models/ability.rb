class Ability
  include CanCan::Ability

  def initialize(user)
    # Assign user group permissions
    user.user_groups.each do |user_group|
      user_group.permissions do |permission|
        grant_privilege(permission.privilege,permission.unit)
      end
    end
    # Assign user permissions
    user.permissions.each do |permission|
      grant_privilege(permission.privilege,permission.unit)
    end
  end
  
  def grant_privilege(privilege,unit)
    self.send(privilege.name,unit)
  end
  
  def read_packages(unit)
    Rails.logger.info("=-=-=-=-=-=-=-=-=-=-=- granting read for packages within #{unit}")
    can :read, Package, :unit_id => unit.id
  end
  
  def modify_packages
    can :update, Package, :unit_id => unit.id
  end
  
  def create_packages(unit)
    can :read, Package, :unit_id => unit.id
  end
  
  def destroy_packages(unit)
    can :destroy, Package, :unit_id => unit.id
  end
end
