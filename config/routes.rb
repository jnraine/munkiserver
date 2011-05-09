Munki::Application.routes.draw do |map|
  # The priority is based upon order of creation:
  # first created -> highest priority.

  map.resources :unit_settings
  map.resources :user_settings
  map.resources :computer_groups
  map.resources :bundles
  map.resources :packages, :collection => {:check_for_updated => :any}
  map.resources :computers, :new => {:import => :get}, :collection => {:create_import => :post}
  map.resources :users
  map.resources :units
  map.resources :shared_packages, :member => {:import => :get}
  match 'install_items/edit_multiple/:computer_id' => 'install_items#edit_multiple', :as => "edit_multiple_install_items", :method => :get
  match 'install_items/update_multiple' => 'install_items#update_multiple', :as => "update_multiple_install_items", :method => :get
  match 'managed_install_reports/:id' => 'managed_install_reports#show', :method => :get

  # Session
  map.login 'login', :action => 'new', :controller => 'sessions'
  map.create_session 'create_session', :action => 'create', :controller => 'sessions'
  map.logout 'logout', :action => 'destroy', :controller => 'sessions'
  # map.change_unit 'change_unit/:unit_id', :action => 'update', :controller => 'sessions'
  match 'unit/:unit_id/:c/:a' => 'sessions#update', :as => 'change_unit'
  
  # Computer checkin URL
  match 'checkin/:id' => 'computers#checkin', :method => :post

  # Make munki-client-friendly URLs
  match ':id.plist', :controller => 'computers', :action => 'show', :format => 'manifest', :id => /[A-Za-z0-9_\-\.:]+/
  match '/configuration/:id.plist', :controller => 'computers', :action => 'show', :format => 'client_prefs', :id => /[A-Za-z0-9_\-\.:]+/
  map.catalog 'catalogs/:unit_id-:environment_name.plist', :action => 'show', :controller => 'catalogs', :format => 'plist'
  map.manifest ':controller/:id.plist', :action => 'show', :format => 'manifest', :id => /[A-Za-z0-9_\-\.%]+/
  map.download_package 'pkgs/:installer_item_location', :controller => 'packages', :action => 'download', :installer_item_location => /.+/

  root :to => "computers#index"
end
