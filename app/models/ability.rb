class Ability
  include CanCan::Ability

  def initialize(opts = {})
    puts "Authenticating..."
    @role, @user, @unit, @computer = opts[:role], opts[:user], opts[:unit], opts[:computer]
    @role ||= Role.current_role(@user, @unit) || :none

    puts @role
    include_privilege @role
  end
  
  private
  def admin
    include_privilege :super_user
    
    can :manage, :all
  end
  
  def super_user
    include_privilege :user
    
    can :manage, Package
  end
  
  def user
    include_privilege :none
    
    can :manage, [Computer, ComputerGroup, Bundle]
    can :read, [Package, :shared_package]
    can :destroy, :session
    
    can :update, UserSetting do |user_setting|
      user_setting.user == @user
    end
    
    can [:show, :update], User do |user|
      user == @user
    end
  end
  
  def none
    can :create, :session
  end
  
  def computer
    # TODO - Check that the "logged in" computer is able to read correct catalog, Computer, and Packages.
    can [:read, :checkin], Computer 
    can :show, :catalog
    can :download, Package
  end
  
  def include_privilege(role)
    send(role.to_sym)
  end
  
  
end
