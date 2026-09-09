Rails.application.routes.draw do
  devise_for :users

  resources :cards do
    collection do
      get :autocomplete
      get :new_from_ai
      post :preview_from_ai
    end
  end
  resources :prompt_templates do
    member do
      post :favorite
      delete :unfavorite
      post :record_usage
    end
  end

  root "home#top"
end
