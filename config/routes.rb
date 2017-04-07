# routing
Rails.application.routes.draw do
  resources :projects do
    resources :evms, :evmbaselines
  end
end
