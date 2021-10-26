Rails.application.routes.draw do
  root to: "words#index"

  resources :users, except: [:index]
  get "signup" => "users#new"

  controller :sessions do
    get "login" => :new
    post "login" => :create
    delete "logout" => :destroy
  end

  resources :words do
    post :toggle_card_created
    collection do
      get :import
      post :upload
    end
  end
end
