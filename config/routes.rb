Marsala::Application.routes.draw do

  resources :admin, :controller => :admin
  resources :customers 
  resources :real_estates
  resources :realtors, :only => :index 
  resources :dealer_infos
  match "first_login/:key" => "customers#first_login", :as => "first_login"
  match "login" => "customers#login", :as => "login"

  devise_for :realtors, :controllers => { :registrations => 'realtors/registrations' }

  match 'dealer_infos/new' => 'dealer_infos#new', :as => "new_dealer_info"
  match 'dealer_infos' => 'dealer_infos#create', :via => :post
  match 'dealer_infos/thank_you' => 'dealer_infos#thank_you', :as => :thank_you

  root :to => 'home#index'

  devise_for :dealers

  resources :dealers do
    get 'dealer_infos'
  end

  devise_for :admins
end
