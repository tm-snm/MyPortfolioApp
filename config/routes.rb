Rails.application.routes.draw do
  devise_for :users

  resources :cards, only: %i[index new create]

  root "home#top"
end
