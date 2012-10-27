Warehouse::Application.routes.draw do
  resources :import_runs, :only => [:index]

  resources :locations do 
    resources :sublocations
  end
  resources :admin, :controller => :admin
  
  get '/customers/:key/listings/sync' => 'listings#sync'
  resources :customers do
    get :reset_password
    resources :listings
  end

  match '/listings/image_update/:id' => "listings#image_update", :via => :post

  resource :customer_infos
  
  match "first_login/:setup_nonce" => "session#first_login", :as => "first_login"
  match "login" => "session#login", :as => "login", :protocol => 'http'
  match 'logout' => "session#logout", :as => "logout", :protocol => 'http'

  root :to => 'home#index'
  devise_for :admins
end
