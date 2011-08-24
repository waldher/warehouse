Marsala::Application.routes.draw do
  resources :real_estates do
    get 'json', :on => :collection
  end

  devise_for :realtors, :controllers => { :registrations => 'realtors/registrations' }

  match 'dealer_infos/new' => 'dealer_infos#new'
  match 'dealer_infos' => 'dealer_infos#create', :via => :post
  match 'dealer_infos/thank_you' => 'dealer_infos#thank_you'

  root :to => 'home#index'

  devise_for :dealers

  resources :dealers do
    get 'dealer_infos'
  end

  devise_for :admins
end
