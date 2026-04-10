# Admin routes protected by AdminConstraint
constraints AdminConstraint.new do
  # Below are the routes for madmin
  namespace :madmin, path: :admin do
    mount MissionControl::Jobs::Engine, at: "/jobs"
    resources :api_keys
    resources :sessions
    resources :users
    root to: "dashboard#show"
  end
end
