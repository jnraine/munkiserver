Munki::Application.routes.draw do  
  resources :units, :except => [:show] do
    member do
      get 'settings/edit' => 'unit_settings#edit'
      put 'settings' => 'unit_settings#update'
    end
  end
  
  resources :users, :except => [:show]
  
  # Session
  match '/login' => "sessions#new"
  match 'create_session' => 'sessions#create'
  match '/logout' => 'sessions#destroy'
  
  # Computer checkin URL
  match 'checkin/:id' => 'computers#checkin', :via => :post

  # Make munki-client-friendly URLs
  match ':id.plist', :controller => 'computers', :action => 'show', :format => 'manifest', :id => /[A-Za-z0-9_\-\.%:]+/, :as => "computer_manifest"
  match 'computers/:id.plist', :controller => 'computers', :action => 'show', :format => 'manifest', :id => /[A-Za-z0-9_\-\.%:]+/
  
  match 'catalogs/:unit_environment' => 'catalogs#show', :format => 'plist', :via => :get
  match 'pkgs/:id' => 'packages#download', :as => 'download_package', :id => /[A-Za-z0-9_\-\.%]+/
  match '/configuration/:id.plist', :controller => 'computers', :action => 'show', :format => 'client_prefs', :id => /[A-Za-z0-9_\-\.:]+/
  
  # add units into URLs
  scope "/:unit_shortname" do
    resources :computers do
      get :import, :on => :new
      get 'managed_install_reports/:id' => 'managed_install_reports#show', :on => :collection, :as => "managed_install_reports"
      get 'environment_change(.:format)', :action => "environment_change", :as => 'environment_change'
      get 'unit_change(.:format)', :action => "unit_change", :as => 'unit_change'
      get 'update_warranty', :action => "update_warranty", :as => 'update_warranty'
      
      collection do
        post :create_import#, :force_redirect
        put :update_multiple
        get :edit_multiple
      end
    end
    
    controller :packages do
      match 'packages(.:format)', :action => 'index', :via => :get, :as => 'packages'
      match 'packages(.:format)', :action => 'create', :via => :post
      
      scope '/packages' do
        match 'add(.:format)', :action => 'new', :via => :get, :as => 'new_package'
        match "shared/import/:id", :action => 'import_shared', :via => :put, :as => "import_shared_package"
        match "shared/import_multiple_shared", :action => 'import_multiple_shared', :via => :put, :as => "import_multiple_shared_packages"
        match "shared", :action => 'index_shared', :via => :get, :as => "shared_packages"
        match 'multiple(.:format)', :action => 'edit_multiple', :via => :get, :as => 'edit_multiple_packages'
        match 'multiple(.:format)', :action => 'update_multiple', :via => :put
        match 'check_for_updates', :action => 'check_for_updates', :via => :get, :as => 'check_for_package_updates'
        get ':package_id/environment_change(.:format)', :action => "environment_change", :as => 'package_environment_change'
        constraints({:version => /.+/}) do
          constraints(ExtractFormatFromParam.new(:version)) do
            match ':package_branch(/:version)/edit(.:format)', :action => 'edit', :via => :get, :as => 'edit_package'
            match ':package_branch(/:version)(.:format)', :action => 'show', :via => :get, :as => 'package'
            match ':package_branch(/:version)(.:format)', :action => 'update', :via => :put
            match ':package_branch(/:version)(.:format)', :action => 'destroy', :via => :delete
          end
        end
      end
    end
    
    resources :user_groups, :except => :show
    
    resources :computer_groups do
      get 'environment_change(.:format)', :action => "environment_change", :as => 'environment_change'
    end
    
    resources :bundles do
      get 'environment_change(.:format)', :action => "environment_change", :as => 'environment_change'
    end
    
    match 'install_items/edit_multiple/:computer_id' => 'install_items#edit_multiple', :as => "edit_multiple_install_items", :via => :get
    match 'install_items/update_multiple' => 'install_items#update_multiple', :as => "update_multiple_install_items", :via => :put
  end
  
  match 'dashboard' => "dashboard#index", :as => "dashboard"
  match 'dashboard/widget/:name' => 'dashboard#widget', :as => "widget"
  
  match "permissions" => "permissions#index", :as => "permissions", :via => "GET"
  match "permissions/edit/:principal_pointer(/:unit_id)" => "permissions#edit", :as => "edit_permissions", :via => "GET"
  match "permissions" => "permissions#update", :as => "update_permissions", :via => "PUT"
  
  root :to => redirect("/login")
end
