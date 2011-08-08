class Ability
  include CanCan::Ability

  def initialize(opts = {})
    puts "Authenticating..."
    @role, @user, @unit = opts[:role], opts[:user], opts[:unit]
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
    can [:show, :update], User do |user|
      user == @user
    end
  end
  
  def none
    can :create, :session
  end
  
  def computer
    can :read, Computer
    can :show, :catalog
    can :checkin, Computer
  end
  
  def include_privilege(role)
    send(role.to_sym)
  end
  
  
end
