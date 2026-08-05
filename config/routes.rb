Rails.application.routes.draw do
  devise_for :users

  resources :cards, only: %i[new create]

  root "home#top"
end
