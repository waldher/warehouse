Marsala::Application.routes.draw do

  resources :admin, :controller => :admin
  
  resources :customers do
    resources :listings
  end
  match "first_login/:setup_nonce" => "customers#first_login", :as => "first_login"

  resource :customer_infos
  
  resources :real_estates
  
  resources :realtors, :only => :index 
  
  match "login" => "customers#login", :as => "login"

  resources :real_estates do
    get 'json', :on => :collection
  end

  root :to => 'home#index'
  resources :dealers

  devise_for :admins
end
