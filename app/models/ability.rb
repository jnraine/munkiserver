class Ability
  include CanCan::Ability
  include PrivilegeGranter

  def initialize(user)
    # Ensure a user is available
    @user = user
    @user ||= User.new
    
    # Permit user to unprotected actions
    permit_unprotected_actions
    
    # Assign user group permissions
    @user.all_permissions.group_by(&:privilege_id).each do |privilege_id,permissions|
      grant_privilege(Privilege.find(privilege_id),permissions.map(&:unit_id))
    end
    
    # Give "admin" user the keys to the house
    if @user.is_root?
      can :manage, :all
    end
  end
  
  def grant_privilege(privilege,unit)
    self.send(privilege.name,unit)
  end
  
  # Permit certain things to all requests
  def permit_unprotected_actions
    # Allow client computer requests
    can :checkin, Computer
    can :show, Computer
    # Allow any request to retrieve catalogs
    can :read, Catalog
    # Allow everyone to edit their user record
    can [:read, :update], User, :id => @user.id
    # Allow anyone to login and logout
    can [:create, :destroy], :session
    # Allow anyone to view their dashboard
    can :manage, :dashboard
  end
end
