require 'resque/server'

Nc3::Application.routes.draw do
  
  mount Resque::Server, at: '/resque'
  
  devise_for :users 
  devise_scope :user do
      get "login", :to => "devise/sessions#new"
      get "logout", :to => "devise/sessions#destroy"
  end

  resources :samples do
    member {get 'activate'}
  end
  
  resources :users
  resources :projects, :documents
  
  resources :classifiers do
    member { get 'classify' }
    member { get 'reset' }
    member { get 'teach' }
    member { get 'test' }
    collection { get 'classify_all' }
    collection { get 'codebook' }
  end
  
  resources :sources do
    member { get 'import' }
    member { get 'reset' }
    collection { get 'import_all' }
  end
  
  
  
  #match 'sources/:id/import' => 'sources#import', :as=>'import_source'
  #match 'classifiers/:id/classify' => 'classifiers#classify', :as=>'classifiers_classify'
  
  #match 'classifiers/codebook'=>'classifiers#codebook'
  root :to => "projects#show"

 #map.home '/', :controller => 'projects', :action=> 'show'
 #map.codebook '/codebook', :controller=> 'classifiers', :action=>'codebook'
 #
 #
 #map.signup '/signup', :controller => 'users', :action => 'new'
 #map.login '/login', :controller => 'session', :action => 'new'
 #map.logout '/logout', :controller => 'session', :action => 'destroy'


  
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

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
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
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
  #       get 'recent', :on => :collection
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
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
