authorization do
  role :admin do
    includes :super_user
    
    has_permission_on :users, :to => :manage
    has_permission_on :units, :to => :manage
    has_permission_on :roles, :to => :manage
  end
  
  role :super_user do
    includes :user
    
    has_permission_on :bundles, :to => :manage
    has_permission_on :packages, :to => :manage
    has_permission_on :shared_packages, :to => :import
    
  end
  
  role :user do
    includes :guest
    has_permission_on [:computer_groups, :computers], :to => :manage
    has_permission_on [:bundles, :packages, :shared_packages], :to => :see
    
    has_permission_on :users, :to => [:modify, :show] do
      if_attribute :id => is { user.id }
    end
    
    has_permission_on :sessions, :to => :destroy
    
  end
    
  role :guest do
    has_permission_on :sessions, :to => [:new, :create]    
  end
end

privileges do
  privilege :manage do
    includes :make, :edit, :update, :delete, :see
  end
  
  privilege :make do
    includes :new, :create
  end
  
  privilege :see do
    includes :index, :show
  end
  
  privilege :modify do
    includes :edit, :update
  end
  
end