require 'sidekiq/web'

Rails.application.routes.draw do
  # Sidekiq Web UI (mounted only in development)
  if Rails.env.development?
    mount Sidekiq::Web => "/sidekiq"
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      devise_for :users,
        controllers: {
          sessions: 'api/v1/users/sessions',
          registrations: 'api/v1/users/registrations'
        },
        path: 'auth',
        path_names: {
          sign_in: 'login',
          sign_out: 'logout',
          registration: 'signup'
        }

      devise_scope :user do
        post 'auth/refresh', to: 'users/refresh#create'
      end

      # LINE Authentication
      namespace :auth do
        post 'line_login', to: 'line_auth#line_login'
        post 'line_link', to: 'line_auth#line_link'
        get 'line_profile', to: 'line_auth#line_profile'
        post 'generate_nonce', to: 'line_auth#generate_nonce'
      end

      # LINE Bot Webhook
      post 'line/webhook', to: 'line#webhook'

      # Ingredients master and user inventory
      resources :ingredients, only: [:index, :create, :update, :destroy]
      resources :user_ingredients

      # Recipes and recipe histories
      resources :recipes, only: [:index, :show]
      resources :recipe_histories, only: [:index, :show, :create, :update, :destroy]
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
