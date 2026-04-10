Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  resources :notifications, only: [:index, :update] do
    collection do
      post :mark_all_read
    end
  end

  draw :madmin
  # API routes
  namespace :api do
    namespace :v1 do
      post "auth/token", to: "auth#create"
    end
  end

  # API keys management
  resources :api_keys, only: [:index, :new, :create, :destroy]
  resources :inboxes, only: [:index]
  resources :messages, only: [] do
    member do
      get :body, to: "message_bodies#show"
      get "inline_assets/:token", to: "message_inline_assets#show", as: :inline_asset
      post :reply, to: "outbound_messages#reply"
      post :reply_all, to: "outbound_messages#reply_all"
      post :forward, to: "outbound_messages#forward"
    end
  end
  resources :outbound_messages, only: [:create, :edit, :update]

  resource :profile, only: [:show, :edit, :update]
  resource :registration, only: [:new, :create]
  resource :session
  resources :passwords, param: :token
  root "inboxes#index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
