Rails.application.routes.draw do
  devise_for :users

  resources :cards, only: %i[index new create show edit update ]  

  root "home#top"
end
