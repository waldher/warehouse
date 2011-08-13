Marsala::Application.routes.draw do
  resources :realators

  match 'dealer_infos/new' => 'dealer_infos#new'
  match 'dealer_infos' => 'dealer_infos#create', :via => :post
  match 'dealer_infos/thank_you' => 'dealer_infos#thank_you'

  
  devise_for :dealers

  devise_for :admins
end
