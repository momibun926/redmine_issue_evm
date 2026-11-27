require File.expand_path("evm_functional_test_helper", __dir__)

# A project has at most one EVM setting. Opening the URL of edit or update
# without a setting, or the URL of new or create with one, goes to the form
# that fits instead of failing or adding a second setting.
class EvmsettingsControllerRedirectTest < Redmine::ControllerTest
  tests EvmsettingsController
  include EvmFunctionalTestSupport

  def setup
    sign_in_as_project_member
  end

  def test_edit_without_a_setting_goes_to_the_new_form
    get :edit, params: { project_id: @project.id, id: @project.id }

    assert_redirected_to "/projects/#{@project.identifier}/evmsettings/new"
  end

  def test_update_without_a_setting_goes_to_the_new_form_and_saves_nothing
    assert_no_difference "Evmsetting.count" do
      patch :update, params: { project_id: @project.id, id: @project.id, evmsetting: { basis_hours: 6 } }
    end

    assert_redirected_to "/projects/#{@project.identifier}/evmsettings/new"
  end

  def test_new_with_a_setting_goes_to_the_edit_form
    setting = create_evm_setting

    get :new, params: { project_id: @project.id }

    assert_redirected_to "/projects/#{@project.identifier}/evmsettings/#{setting.id}/edit"
  end

  def test_create_with_a_setting_adds_no_second_setting
    setting = create_evm_setting

    assert_no_difference "Evmsetting.count" do
      post :create, params: { project_id: @project.id, evmsetting: { basis_hours: 6 } }
    end

    assert_redirected_to "/projects/#{@project.identifier}/evmsettings/#{setting.id}/edit"
    assert_not_equal 6.0, setting.reload.basis_hours
  end

  def test_without_the_manage_permission_edit_is_denied_before_the_redirect
    Role.find(1).remove_permission!(:manage_evmsettings)

    get :edit, params: { project_id: @project.id, id: @project.id }

    assert_response :forbidden
  end
end
