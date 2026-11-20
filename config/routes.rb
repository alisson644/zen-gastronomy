Rails.application.routes.draw do
  get "financial/index"
  get "home/index"
  devise_for :users, controllers: { registrations: "users/registrations" }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
  resources :team_members, only: [ :index, :new, :create, :destroy ] do
    resource :password, only: [ :edit, :update ], controller: "team_member_passwords"
  end
  resources :roles, except: [ :show ]

  namespace :admin do
    resources :companies, only: [ :index ]
    resource :company_view, only: [ :create, :destroy ]
  end
  resource :avatar, only: [ :update ]
  resources :accounts
  resources :movements do
    patch :pay, on: :member
  end
  resources :categories, only: [ :create ]
  resources :subcategories, only: [ :create ]

  # Estoque
  resource :stock, only: :show, controller: "stock"
  resources :products
  resources :suppliers
  resources :stock_entries, only: [ :index, :new, :create, :show ]
  resources :stock_outputs, only: [ :new, :create ]
  resources :stock_counts, only: [ :index, :create, :show, :update ] do
    patch :finalize, on: :member
  end
end
