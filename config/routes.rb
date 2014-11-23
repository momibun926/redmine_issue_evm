Rails.application.routes.draw do
  resources :projects do
    resources :evms
  end
end