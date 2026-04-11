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

      resources :folders
      resources :files, controller: "stored_files"

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
          post :junk
          post :not_junk
          post :archive
          post :restore
          post :trash
          post :mark_read
          post :mark_unread
          post :star
          post :unstar
          post :block_sender
          post :unblock_sender
          post :block_domain
          post :unblock_domain
          post :trust_sender
          post :untrust_sender
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
  resources :domains do
    resources :inboxes, except: [:index, :show]
  end
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
      post :junk, to: "message_organizations#junk"
      post :not_junk, to: "message_organizations#not_junk"
      post :archive, to: "message_organizations#archive"
      post :restore, to: "message_organizations#restore"
      post :trash, to: "message_organizations#trash"
      post :mark_read, to: "message_organizations#mark_read"
      post :mark_unread, to: "message_organizations#mark_unread"
      post :star, to: "message_organizations#star"
      post :unstar, to: "message_organizations#unstar"
      post :block_sender, to: "message_organizations#block_sender"
      post :unblock_sender, to: "message_organizations#unblock_sender"
      post :block_domain, to: "message_organizations#block_domain"
      post :unblock_domain, to: "message_organizations#unblock_domain"
      post :trust_sender, to: "message_organizations#trust_sender"
      post :untrust_sender, to: "message_organizations#untrust_sender"
      patch :labels, to: "message_organizations#labels"
      patch :invitation, to: "message_invitations#update"
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

  get "/calendar", to: "calendars/home#show", as: :calendar
  namespace :calendars, path: "calendar" do
    resources :calendars, only: [:index, :new, :create, :edit, :update]
    resources :events, only: [:show, :new, :create, :edit, :update, :destroy]
    resources :imports, only: [:new, :create]
  end

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
