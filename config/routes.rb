Munki::Application.routes.draw do |map|
  # The priority is based upon order of creation:
  # first created -> highest priority.

  map.resources :unit_settings
  map.resources :user_settings
  map.resources :computer_groups
  map.resources :bundles
  map.resources :packages
  map.resources :computers, :new => {:import => :get}, :collection => {:create_import => :any}
  map.resources :users
  map.resources :units

  # Session
  map.login 'login', :action => 'new', :controller => 'sessions'
  map.create_session 'create_session', :action => 'create', :controller => 'sessions'
  map.logout 'logout', :action => 'destroy', :controller => 'sessions'
  # map.change_unit 'change_unit/:unit_id', :action => 'update', :controller => 'sessions'
  match 'unit/:unit_id/:c/:a' => 'sessions#update', :as => 'change_unit'

  # Make munki-client-friendly URLs
  map.catalog 'catalogs/:unit_id-:environment_name.plist', :action => 'show', :controller => 'catalogs', :format => 'plist'
  map.manifest ':controller/:id-:name.plist', :action => 'show', :format => 'plist', :name => /[A-Za-z0-9_\.]+/
  map.download_package 'packages/:installer_item_location', :controller => 'packages', :action => 'download', :installer_item_location => /.+/

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
