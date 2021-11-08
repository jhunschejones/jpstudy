Rails.application.routes.draw do
  root to: "words#index"

  resources :users, except: [:index]
  get "signup" => "users#new"

  controller :sessions do
    get "login" => :new
    post "login" => :create
    delete "logout" => :destroy
  end

  get "password/forgot", to: "passwords#forgot_form"
  post "password/forgot", to: "passwords#forgot"
  get "password/reset", to: "passwords#reset_form"
  post "password/reset", to: "passwords#reset"

  get "email/verify", to: "emails#verify"

  resources :square, only: [] do
    collection do
      post :subscription_created
      post :subscription_updated
      get :logout # redirect from square
    end
  end

  resources :words do
    post :toggle_card_created
    collection do
      get :import
      post :upload
      get :export
      get :download
    end
  end
end
