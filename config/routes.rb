Munki::Application.routes.draw do  

  resources :computers do
    get :import, :on => :new
    collection do
      post :create_import, :multiple_edit
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
  resources :units
  resources :unit_settings, :user_settings, :computer_groups, :bundles, :users
  
  
  # match 'test/info' => 'test#info'
  match 'install_items/edit_multiple/:computer_id' => 'install_items#edit_multiple', :as => "edit_multiple_install_items", :method => :get
  match 'install_items/update_multiple' => 'install_items#update_multiple', :as => "update_multiple_install_items", :method => :get
  match 'managed_install_reports/:id' => 'managed_install_reports#show', :method => :get

  # Session
  match '/login' => "sessions#new"
  match 'create_session' => 'sessions#create'
  match '/logout' => 'sessions#destroy'
  match 'unit/:unit_id/:c/:a' => 'sessions#update', :as => 'change_unit'
  
  # Computer checkin URL
  match 'checkin/:id' => 'computers#checkin', :method => :post

  # Make munki-client-friendly URLs
  match ':id.plist', :controller => 'computers', :action => 'show', :format => 'manifest', :id => /[A-Za-z0-9_\-\.%:]+/
  match 'catalogs/:unit_id-:environment_name.plist' => 'catalogs#show', :format => 'plist'
  match ':unit_name/:controller/:id.plist', :action => 'show', :format => 'manifest', :id => /[A-Za-z0-9_\-\.%]+/, :as => 'manifest'
  match 'pkgs/:id' => 'packages#download', :as => 'download_package', :id => /[A-Za-z0-9_\-\.%]+/
  match '/configuration/:id.plist', :controller => 'computers', :action => 'show', :format => 'client_prefs', :id => /[A-Za-z0-9_\-\.:]+/

  root :to => "computers#index"
end
