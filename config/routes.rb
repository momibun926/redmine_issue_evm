if Rails::VERSION::MAJOR < 3
  ActionController::Routing::Routes.draw do |map|
    map.connect 'glossary_styles/:action', :controller => 'glossary_styles'
    map.with_options :controller => 'glossary' do |submap|
      submap.connect 'projects/:project_id/glossary', :action => 'index'
      submap.connect 'projects/:project_id/glossary/new', :action => 'new'
      submap.connect 'projects/:project_id/glossary/:id', :action => 'show', :id => /\d+/
      submap.connect 'projects/:project_id/glossary/:action'
      submap.connect 'projects/:project_id/glossary/:id/:action', :id => /\d+/
    end
    map.with_options :controller => 'term_categories' do |submap|
      submap.connect 'projects/:project_id/term_categories', :action => 'index'
      submap.connect 'projects/:project_id/term_categories/:action'
      submap.connect 'projects/:project_id/term_categories/:id/:action', :id => /\d+/
    end
  end
else
  RedmineApp::Application.routes.draw do
    match 'glossary_styles/:action', :to => 'glossary_styles', :via => [ :get, :post, :put ]

    match 'projects/:project_id/glossary', :to => 'glossary#index', :via => [ :get ]
    match 'projects/:project_id/glossary/new', :to => 'glossary#new', :via => [ :get ]
    match 'projects/:project_id/glossary/edit', :to => 'glossary#edit', :via => [ :get, :post ]
    match 'projects/:project_id/glossary/:id/edit', :to => 'glossary#edit', :id => /\d+/, :via => [ :get, :post ]
    match 'projects/:project_id/glossary/:id/:action', :to => 'glossary', :id => /\d+/
    match 'projects/:project_id/glossary/:id', :to => 'glossary#show', :id => /\d+/, :via => [ :get ]
    match 'projects/:project_id/glossary/destroy', :to => 'glossary#destroy', :via => [ :delete ]
    match 'projects/:project_id/glossary/:action', :to => 'glossary'

    match 'projects/:project_id/term_categories', :to => 'term_categories#index'
    match 'projects/:project_id/term_categories/destroy', :to => 'term_categories#destroy', :via => [ :delete ]
    match 'projects/:project_id/term_categories/change_order', :to => 'term_categories#change_order', :via => [ :post ]
    match 'projects/:project_id/term_categories/:action', :to => 'term_categories'
    match 'projects/:project_id/term_categories/:id/:action', :to => 'term_categories', :id => /\d+/
  end
end

