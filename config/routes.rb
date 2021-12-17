Rails.application.routes.draw do
  root to: "words#index"

  controller :static_pages do
    get "about" => :about
    get "word_list_instructions" => :word_list_instructions
    get "word_limit" => :word_limit_explanation
    get "keyboard_shortcuts" => :keyboard_shortcuts
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

  get "/signup", to: "users#new"
  resources :users, except: [:index], param: :username do
    member do
      get :stats
      get :edit_targets
      get :before_you_go
      get :in_out
    end
  end

  resource :square, only: [] do
    collection do
      post :subscription_created
      post :subscription_updated
      get :logout # a redirect from square checkout
    end
  end

  resources :words do
    post :toggle_card_created
    collection do
      get :import
      post :upload
      get :export
      get :download
      delete :destroy_all
      get :search
    end
  end

  resource :kanji, only: [:create], controller: :kanji do
    collection do
      get :next
      get :import
      post :upload
      get :export
      get :download
    end
  end
end
