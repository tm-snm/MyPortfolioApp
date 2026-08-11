Rails.application.routes.draw do
  devise_for :users

  resources :cards, only: %i[index new create show edit update destroy]
  resources :prompt_templates, only: %i[index show]

  root "home#top"
end
