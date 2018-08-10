require File.expand_path('../../test_helper', __FILE__)

class GlossaryTermsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles
  plugin_fixtures :glossary_terms
  
  def setup
    @project = projects('projects_001')
    @project.enabled_module_names = [:glossary]
    roles('roles_001').add_permission! :view_glossary, :manage_glossary
  end
  
  def test_index
    @request.session[:user_id] = users('users_002').id
    get :index, params: {project_id: 1}
    assert_response :success
  end

  def test_edit
    @request.session[:user_id] = users('users_002').id
    get :edit, params: {id: 1, project_id: 1}
    assert_response :success
    assert_select 'form', true
  end

  def test_update
    @request.session[:user_id] = users('users_002').id
    patch :update, params: {id: 1, project_id: 1, glossary_term: {
      name: 'rosso'
    }}
    term = GlossaryTerm.find(1)
    assert_redirected_to project_glossary_term_path(@project, term)
    assert_equal 'rosso', term.name
  end

  def test_new
    @request.session[:user_id] = users('users_002').id
    get :new, params: {project_id: 1}
    assert_response :success
    assert_select 'form', true
  end

  def test_create
    @request.session[:user_id] = users('users_002').id
    post :create, params: { project_id: 1, glossary_term: {
      name: 'white', category_id: 1
    }}
    term = GlossaryTerm.find_by(name: 'white')
    assert_not_nil term
    assert_redirected_to project_glossary_term_path(@project, term)
  end
  
  def test_destroy
    @request.session[:user_id] = users('users_002').id
    delete :destroy, params: {id: 1, project_id: 1}
    assert_raise(ActiveRecord::RecordNotFound) { GlossaryTerm.find(1) }
    assert_redirected_to project_glossary_terms_path(@project)
  end
end
