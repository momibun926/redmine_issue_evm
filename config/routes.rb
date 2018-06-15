# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

Rails.application.routes.draw do
  resources :projects do
    resources :glossary_terms do
      member do
        patch 'preview'
      end
      collection do
        post 'preview'
      end
    end
    resources :glossary_categories
  end
end
