require File.expand_path('../../test_helper', __FILE__)

class GlossaryCategoriesControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles
  plugin_fixtures :glossary_categories
  
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
    patch :update, params: {id: 1, project_id: 1, glossary_category: {name: 'Colour'}}
    category = GlossaryCategory.find(1)
    assert_redirected_to project_glossary_category_path(@project, category)
    assert_equal 'Colour', category.name
  end

  def test_new
    @request.session[:user_id] = users('users_002').id
    get :new, params: {id: 1, project_id: 1}
    assert_response :success
    assert_select 'form', true
  end

  def test_create
    @request.session[:user_id] = users('users_002').id
    post :create, params: {
      project_id: 1, glossary_category: {name: 'Material'}
    }
    category = GlossaryCategory.find_by(name: 'Material')
    assert_not_nil category
    assert_redirected_to project_glossary_category_path(@project, category)
  end
end
