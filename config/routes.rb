Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: "home#index"

  get '/auth/:provider/callback', to: 'sessions#create'

  get 'auth/failure' => redirect('/')
  get 'signout' => 'sessions#destroy', as: 'signout'

end
