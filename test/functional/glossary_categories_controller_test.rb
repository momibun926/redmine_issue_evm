require File.expand_path('../../test_helper', __FILE__)

class GlossaryCategoriesControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles

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
end
