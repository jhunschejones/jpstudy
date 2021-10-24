Rails.application.routes.draw do
  resources :words do
    post :toggle_card_created
  end
end
