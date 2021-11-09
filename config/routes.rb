Rails.application.routes.draw do
  root to: "static_pages#about"

  controller :static_pages do
    get "about" => :about
  end

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

  resources :users, except: [:index], param: :username
  get "signup" => "users#new"

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
