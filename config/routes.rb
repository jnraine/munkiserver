Munki::Application.routes.draw do  
  match 'units/:unit/settings' => 'unit_settings#show', :as => 'unit_setting', :via => :get
  match 'units/:unit/settings/edit' => 'unit_settings#edit', :as => 'edit_unit_setting', :via => :get
  match 'units/:unit/settings' => 'unit_settings#update', :via => :put
  
  match 'users/:id/settings/edit' => 'user_settings#edit', :as => 'edit_user_setting', :via => :get
  match 'users/:id/settings' => 'user_settings#update', :via => :put
  # Non-unit specific resources
  resources :units, :users 
  
  # Session
  match '/login' => "sessions#new"
  match 'create_session' => 'sessions#create'
  match '/logout' => 'sessions#destroy'
  
  # Computer checkin URL
  match 'checkin/:id' => 'computers#checkin', :via => :post

  # Make munki-client-friendly URLs
  match ':id.plist', :controller => 'computers', :action => 'show', :format => 'manifest', :id => /[A-Za-z0-9_\-\.%:]+/
  match 'catalogs/:unit_id-:environment_name.plist' => 'catalogs#show', :format => 'plist'
  match ':unit_name/:controller/:id.plist', :action => 'show', :format => 'manifest', :id => /[A-Za-z0-9_\-\.%]+/, :as => 'manifest'
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
    match 'install_items/update_multiple' => 'install_items#update_multiple', :as => "update_multiple_install_items", :via => :get
  end
  
  root :to => redirect("/login")
end
