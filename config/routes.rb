Rails.application.routes.draw do
  devise_for :users

  resources :cards, only: %i[index new create show edit update destroy]

  root "home#top"
end
