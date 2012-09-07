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

