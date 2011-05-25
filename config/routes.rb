Munki::Application.routes.draw do |map|
  # get "test/info"

  # The priority is based upon order of creation:
  # first created -> highest priority.

    resources :computers do
      get :import, :on => :new
      collection do
        post :create_import
      end
    end

    resources :units
    resources :unit_settings
    resources :user_settings
    resources :computer_groups
    resources :bundles
    resources :users
  
    # map.resources :packages, :collection => {:check_for_updated => :any}
    resources :packages do
      collection do
        get :check_for_updated
        put :check_for_updated
      end
    end
    # map.resources :computers, :new => {:import => :get}, :collection => {:create_import => :post}
    # map.resources :shared_packages, :member => {:import => :get}
    resources :shared_packages do
      get :import, :on => :member
    end
  

  
  match 'install_items/edit_multiple/:computer_id' => 'install_items#edit_multiple', :as => "edit_multiple_install_items", :method => :get
  match 'install_items/update_multiple' => 'install_items#update_multiple', :as => "update_multiple_install_items", :method => :get
  match 'managed_install_reports/:id' => 'managed_install_reports#show', :method => :get

  # Session
  # map.login 'login', :action => 'new', :controller => 'sessions'
  match '/login' => "sessions#new"
  # map.create_session 'create_session', :action => 'create', :controller => 'sessions'
  match 'create_session' => 'sessions#create'
  # map.logout 'logout', :action => 'destroy', :controller => 'sessions'
  match '/logout' => 'sessions#destroy'
  # map.change_unit 'change_unit/:unit_id', :action => 'update', :controller => 'sessions'
  match 'unit/:unit_id/:c/:a' => 'sessions#update', :as => 'change_unit'
  
  # match '/:unit_name/:computer_name' => 'computers#show'
  # match ':unit/:id' => 'computers#show', :id => /[A-Za-z0-9_\-\.%]+/
  # , :constraints => {:computer_hostname => /A-Za-z0-9\._\-+/ }/
  #, :comptuer_name => /[^\/]/+
  
  
  # match '/:comptuer_mac_address' => 'test#info'
  # Computer checkin URL
  match 'checkin/:id' => 'computers#checkin', :method => :post


  # Make munki-client-friendly URLs
  match ':id.plist', :controller => 'computers', :action => 'show', :format => 'manifest', :id => /[A-Za-z0-9_\-\.%:]+/
  # map.catalog 'catalogs/:unit_id-:environment_name.plist', :action => 'show', :controller => 'catalogs', :format => 'plist'
  match 'catalogs/:unit_id-:environment_name.plist' => 'catalogs#show', :format => 'plist'
  map.manifest ':controller/:id.plist', :action => 'show', :format => 'manifest', :id => /[A-Za-z0-9_\-\.%]+/
  # match ':controller/:id.plist' => 'manifest#show', :format => 'manifest', :id => /[A-Za-z0-9_\-\.%]+/, :as => 'manifest'
  

  map.download_package 'pkgs/:installer_item_location', :controller => 'packages', :action => 'download', :installer_item_location => /.+/
  
  # match 'pkgs/:installer_item_location' => 'package#download' , :installer_item_location => /.+/

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get :short
  #       post :toggle
  #     end
  #
  #     collection do
  #       get :sold
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get :recent, :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "users"
  root :to => "computers#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
