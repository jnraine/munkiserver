Munki::Application.routes.draw do  

  # Non-unit specific resources
  resources :units, :users, :user_settings, :unit_settings
 
  # Session
  match '/login' => "sessions#new"
  match 'create_session' => 'sessions#create'
  match '/logout' => 'sessions#destroy'
  
  # Computer checkin URL
  match 'checkin/:id' => 'computers#checkin', :method => :post

  # Make munki-client-friendly URLs
  match ':id.plist', :controller => 'computers', :action => 'show', :format => 'manifest', :id => /[A-Za-z0-9_\-\.%:]+/
  match 'catalogs/:unit_id-:environment_name.plist' => 'catalogs#show', :format => 'plist'
  match ':unit_name/:controller/:id.plist', :action => 'show', :format => 'manifest', :id => /[A-Za-z0-9_\-\.%]+/, :as => 'manifest'
  match 'pkgs/:id' => 'packages#download', :as => 'download_package', :id => /[A-Za-z0-9_\-\.%]+/
  match '/configuration/:id.plist', :controller => 'computers', :action => 'show', :format => 'client_prefs', :id => /[A-Za-z0-9_\-\.:]+/
  
  # add units into URLs
  scope "/:units" do
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
    
    match 'install_items/edit_multiple/:computer_id' => 'install_items#edit_multiple', :as => "edit_multiple_install_items", :method => :get
    match 'install_items/update_multiple' => 'install_items#update_multiple', :as => "update_multiple_install_items", :method => :get
  end
  
  root :to => redirect("/login")
end
