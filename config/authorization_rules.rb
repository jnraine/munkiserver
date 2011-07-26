authorization do
  role :admin do
    includes :super_user
    
    has_permission_on :users, :to => :manage
    has_permission_on :units, :to => :manage
    has_permission_on :roles, :to => :manage
  end
  
  role :super_user do
    includes :user
    
    has_permission_on :packages, :to => :manage
    has_permission_on :shared_packages, :to => [:manage, :import]
  end
  
  role :user do
    includes :guest
    
    has_permission_on [:computer_groups, :computers, :bundles], :to => :manage
    has_permission_on [:packages], :to => :read
    
    has_permission_on :sessions, :to => :destroy
    has_permission_on :users, :to => [:modify, :show] do
      if_attribute :id => is { user.id }
    end
  end
    
  role :guest do
    has_permission_on :sessions, :to => [:new, :create]    
  end
end

privileges do
  privilege :manage do
    includes :make, :modify, :delete, :read
  end
  
  privilege :make do
    includes :new, :create
  end
  
  privilege :read do
    includes :index, :show
  end
  
  privilege :modify do
    includes :edit, :update
  end
  
end