Marsala::Application.routes.draw do
  resources :admin, :controller => :admin
  resources :customers 
  resource :customer_infos
  resources :real_estates
  resources :realtors, :only => :index 
  match "first_login/:setup_nonce" => "session#first_login", :as => "first_login"
  match "login" => "session#login", :as => "login"
  match 'logout' => "session#logout", :as => "logout"

  resources :real_estates do
    get 'json', :on => :collection
  end

  root :to => 'home#index'
  resources :dealers

  devise_for :admins
end
