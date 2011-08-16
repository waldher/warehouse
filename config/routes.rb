Marsala::Application.routes.draw do
  resources :realestates

  devise_for :users

  resources :realators

  match 'dealer_infos/new' => 'dealer_infos#new'
  match 'dealer_infos' => 'dealer_infos#create', :via => :post
  match 'dealer_infos/thank_you' => 'dealer_infos#thank_you'

  match 'realtors/new' => 'realators#new'
  
  match 'realtors/edit' => 'realators#edit'
  match 'realtors/:id' => "realtors#show"
  root :to => 'home#index'

  devise_for :dealers

  devise_for :admins
end
