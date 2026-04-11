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

      resource :me, only: [:show, :update], controller: :me
      resources :api_keys, only: [:index, :create, :show, :update, :destroy]
      resources :labels, only: [:index, :create, :show, :update, :destroy]

      resources :domains do
        member do
          get :outbound_status
          post :validate_outbound
        end
      end

      resources :inboxes do
        member do
          get :pipeline
          post :test_forwarding_rules
        end

        resources :messages, only: [:index]
        resources :conversations, only: [:index]
      end

      resources :conversations, only: [:index, :show] do
        member do
          get :timeline
          post :archive
          post :restore
          post :trash
          patch :labels
        end

        resources :messages, only: [:index]
      end

      resources :messages, only: [:index, :show] do
        member do
          get :body
          post :reply
          post :reply_all
          post :forward
          post :archive
          post :restore
          post :trash
          post :mark_read
          post :mark_unread
          post :star
          post :unstar
          patch :labels
          get "inline_assets/:token", to: "message_inline_assets#show", as: :inline_asset
        end

        resources :attachments, only: [:index, :show], controller: "message_attachments" do
          member do
            get :download
          end
        end
      end

      resources :outbound_messages do
        member do
          post :send_message
          post :queue
        end

        resources :attachments, only: [:index, :show, :create, :destroy], controller: "outbound_message_attachments" do
          member do
            get :download
          end
        end
      end

      resources :notifications, only: [:index, :show, :update] do
        collection do
          post :mark_all_read
        end
      end

      resources :pipelines, only: [:index, :show], param: :key
      get :capabilities, to: "capabilities#show"
      get :health, to: "health#show"
    end
  end

  # API keys management
  resources :api_keys, only: [:index, :new, :create, :destroy]
  resources :email_signatures
  resources :email_templates
  resources :labels, only: [:create, :destroy]
  resources :inboxes, only: [:index]
  resources :messages, only: [] do
    member do
      get :body, to: "message_bodies#show"
      get "inline_assets/:token", to: "message_inline_assets#show", as: :inline_asset
      post :reply, to: "outbound_messages#reply"
      post :reply_all, to: "outbound_messages#reply_all"
      post :forward, to: "outbound_messages#forward"
      post :archive, to: "message_organizations#archive"
      post :restore, to: "message_organizations#restore"
      post :trash, to: "message_organizations#trash"
      post :mark_read, to: "message_organizations#mark_read"
      post :mark_unread, to: "message_organizations#mark_unread"
      post :star, to: "message_organizations#star"
      post :unstar, to: "message_organizations#unstar"
      patch :labels, to: "message_organizations#labels"
    end

    resources :attachments, only: [:show], controller: "message_attachments" do
      member do
        get :download
      end
    end
  end
  resources :conversations, only: [] do
    member do
      post :archive, to: "conversation_organizations#archive"
      post :restore, to: "conversation_organizations#restore"
      post :trash, to: "conversation_organizations#trash"
      patch :labels, to: "conversation_organizations#labels"
    end
  end
  resources :outbound_messages, only: [:create, :edit, :update, :destroy] do
    resources :attachments, only: [:show], controller: "outbound_message_attachments" do
      member do
        get :download
      end
    end
  end

  resource :profile, only: [:show, :edit, :update]
  resource :registration, only: [:new, :create]
  resource :session
  resources :passwords, param: :token

  get "/welcome", to: "static/landing#show", as: :welcome
  root "inboxes#index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*.
  get "manifest.json" => "rails/pwa#manifest", :as => :pwa_manifest
  get "service-worker.js" => "rails/pwa#service_worker", :as => :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
