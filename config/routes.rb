Munki::Application.routes.draw do  
  resources :units do
    member do
      get 'settings/edit' => 'unit_settings#edit'
      put 'settings' => 'unit_settings#update'
    end
  end
  
  resources :users do
    member do
      get 'settings/edit' => 'user_settings#edit'
      put 'settings' => 'user_settings#update'
    end
  end
  
  # Session
  match '/login' => "sessions#new"
  match 'create_session' => 'sessions#create'
  match '/logout' => 'sessions#destroy'
  
  # Computer checkin URL
  match 'checkin/:id' => 'computers#checkin', :via => :post

  # Make munki-client-friendly URLs
  match ':id.plist', :controller => 'computers', :action => 'show', :format => 'manifest', :id => /[A-Za-z0-9_\-\.%:]+/
  match 'catalogs/:unit_id-:environment_name.plist' => 'catalogs#show', :format => 'plist'
  match 'pkgs/:id' => 'packages#download', :as => 'download_package', :id => /[A-Za-z0-9_\-\.%]+/
  match '/configuration/:id.plist', :controller => 'computers', :action => 'show', :format => 'client_prefs', :id => /[A-Za-z0-9_\-\.:]+/
  
  # add units into URLs
  scope "/:unit" do
    resources :computers do
      get :import, :on => :new
      get 'managed_install_reports/:id' => 'managed_install_reports#show', :on => :collection, :as => "managed_install_reports"
      collection do
        post :create_import, :multiple_edit, :force_redirect
        put :multiple_update
      end
    end
    
    controller :packages do
      match 'packages(.:format)', :action => 'index', :via => :get, :as => 'npackages'
      match 'packages(.:format)', :action => 'create', :via => :post
      
      scope '/packages' do
        constraints({:version => /.+/}) do
          match ':package_branch/:version(.:format)', :action => 'show', :via => :get, :as => 'npackage'
          match ':package_branch/:version/edit(.:format)', :action => 'edit', :via => :get, :as => 'edit_npackage'
          match ':package_branch/:version(.:format)', :action => 'update', :via => :put
          match ':package_branch/:version(.:format)', :action => 'delete', :via => :delete
        end
        match 'add(.:format)', :action => 'new', :via => :get, :as => 'new_npackage'
        match 'multiple(.:format)', :action => 'edit_multiple', :via => :get, :as => 'edit_multiple_npackages'
        match 'multiple(.:format)', :action => 'update_multiple', :via => :put
        match 'check_for_updates', :action => 'check_for_updates', :via => :get, :as => 'check_for_package_updates'
      end
    end
    
    resources :packages do
      collection do
        post :multiple_edit
        get :check_for_updated
        put :check_for_updated, :multiple_update
      end
    end
    
    resources :shared_packages do
      get :import, :on => :member
    end
    
    resources :computer_groups, :bundles
    
    match 'install_items/edit_multiple/:computer_id' => 'install_items#edit_multiple', :as => "edit_multiple_install_items", :via => :get
    match 'install_items/update_multiple' => 'install_items#update_multiple', :as => "update_multiple_install_items", :via => :put
  end
  
  root :to => redirect("/login")
end
