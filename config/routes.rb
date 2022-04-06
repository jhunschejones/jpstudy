Rails.application.routes.draw do
  root to: "sessions#login"

  controller :static_pages do
    get "about" => :about
    get "word_list_instructions" => :word_list_instructions
    get "next_kanji_instructions" => :next_kanji_instructions
    get "content_limits" => :content_limits
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
  resources :users, except: [:index], param: :username, path: "" do
    member do
      get :stats
      get :edit_targets
      get :before_you_go
      get :in_out
    end
  end

  resource :square, only: [], controller: :square do
    collection do
      post :subscription_created
      post :subscription_updated
      get :logout # a redirect from square checkout
    end
  end

  scope ":username", constraints: { username: /[a-zA-Z0-9]+/ } do
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

    # If we call this `resources` it names the url resource correctly but uses
    # routenames like `kanji_index`
    resource :kanji, only: [:create], controller: :kanji do
      collection do
        get :next
        get :import
        post :upload
        get :export
        get :download
        delete :destroy_all
        get :wall
      end
    end
    # This is really the only way to make these routes play nice
    delete "/kanji/:id", to: "kanji#destroy", as: :delete_kanji
  end

  resources :media_tools, only: [] do
    collection do
      get :audio
      post :japanese_to_audio
    end
  end
end
