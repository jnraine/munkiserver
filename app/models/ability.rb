class Ability
  include CanCan::Ability
  include PrivilegeGranter

  def initialize(user)
    @user = user
    permit_unprotected_actions
    
    # Assign user group permissions
    user.all_permissions.group_by(&:privilege_id).each do |privilege_id,permissions|
      grant_privilege(Privilege.find(privilege_id),permissions.map(&:unit_id))
    end
  end
  
  def grant_privilege(privilege,unit)
    self.send(privilege.name,unit)
  end
  
  # Permit certain things to all requests
  def permit_unprotected_actions
    # Allow any request to checkin
    can :checkin, Computer
    # Allow everyone to edit their user record
    can [:read, :update], User, :id => @user.id
  end
end
