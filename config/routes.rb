Marsala::Application.routes.draw do
  resources :admin, :controller => :admin
  resources :customers 
  resource :customer_infos
  resources :real_estates
  resources :realtors, :only => :index 
  match "first_login/:key" => "customers#first_login", :as => "first_login"
  match "login" => "customers#login", :as => "login"

  resources :real_estates do
    get 'json', :on => :collection
  end

  root :to => 'home#index'
  resources :dealers

  devise_for :admins
end
