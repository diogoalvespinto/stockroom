Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  root "stock#index"
  resources :receipts, only: %i[new create]
  resources :issues, only: %i[new create]

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :warehouses, only: :index
      resources :items, only: :index do
        resources :lots, only: :index
      end
      resources :receipts, :issues, :transfers, :adjustments, only: :create

      match "*path", to: "base#route_not_found", via: :all
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
