Rails.application.routes.draw do
  devise_for :users,
             controllers: {
               registrations: "users/registrations",
               sessions: "users/sessions",
               passwords: "users/passwords"
             }

  get "account/deletion",
      to: "account_deletions#show",
      as: :account_deletion

  get "terms", to: "pages#terms", as: :terms
  get "privacy", to: "pages#privacy", as: :privacy
  get "contact", to: "pages#contact", as: :contact

  resource :dashboard, only: :show

  resources :cards do
    collection do
      get :autocomplete
      get :new_from_ai
      post :preview_from_ai
    end
    member do
      get :export_markdown
      patch :schedule_review
      patch :mark_reviewed
      delete :cancel_review
      patch :learning_metadata,
            to: "cards#update_learning_metadata"
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
