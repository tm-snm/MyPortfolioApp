Rails.application.routes.draw do
  devise_for :users

  resources :cards do
    collection do
      get :new_from_ai
      post :preview_from_ai
    end
  end
  resources :prompt_templates, only: %i[index show]

  root "home#top"
end
