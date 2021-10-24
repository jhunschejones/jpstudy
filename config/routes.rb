Rails.application.routes.draw do
  root to: "words#index"

  resources :words do
    post :toggle_card_created
  end
end
