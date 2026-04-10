# Admin routes protected by AdminConstraint
constraints AdminConstraint.new do
  # Below are the routes for madmin
  namespace :madmin, path: :admin do
    resources :domains
    resources :inboxes
    mount MissionControl::Jobs::Engine, at: "/jobs"
    resources :api_keys
    resources :messages
    resources :sessions
    resources :users
    root to: "dashboard#show"
  end
  mount MaintenanceTasks::Engine, at: "/admin/maintenance_tasks"
  mount Flipper::UI.app(Flipper), at: "/admin/flipper"
end
