require File.expand_path("evm_functional_test_helper", __dir__)

# Functional tests of EvmsettingsController (the project's EVM plugin setting).
class EvmsettingsControllerTest < Redmine::ControllerTest
  include EvmFunctionalTestSupport

  def setup
    sign_in_as_project_member
  end

  def test_new
    get :new, params: { project_id: @project.id }

    assert_response :success
    assert controller_ivar(:evm_settings).new_record?
    assert_select "form"
  end

  def test_edit_has_the_back_link_with_an_icon
    create_evm_setting

    get :edit, params: { project_id: @project.id, id: 1 }

    assert_link_icon I18n.t(:button_back), "arrow-narrow-left"
  end

  def test_create_saves_the_setting_for_the_project_and_the_current_user
    assert_difference "Evmsetting.count", 1 do
      post :create, params: { project_id: @project.id, evmsetting: setting_params }
    end

    assert_redirected_to "/projects/#{@project.id}/evms"
    setting = Evmsetting.find_by!(project_id: @project.id)
    assert_equal 2, setting.user_id
    assert_equal [true, false, true, false], [setting.view_forecast, setting.view_version,
                                              setting.view_performance, setting.view_issuelist]
    assert_equal ["method3", 7.5, 0.8, 0.7, 0.6, "us"],
                 [setting.etc_method, setting.basis_hours, setting.threshold_spi, setting.threshold_cpi,
                  setting.threshold_cr, setting.region]
  end

  def test_create_with_invalid_values_shows_the_form_again
    assert_no_difference "Evmsetting.count" do
      post :create, params: { project_id: @project.id, evmsetting: setting_params.merge(basis_hours: 0) }
    end

    assert_response :success
    assert_select "form"
  end

  def test_edit_shows_the_setting_and_the_user_who_saved_it
    create_evm_setting

    get :edit, params: { project_id: @project.id, id: 1 }

    assert_response :success
    assert_equal @project.id, controller_ivar(:evm_settings).project_id
    assert_equal User.find(2).name, controller_ivar(:update_user)
  end

  def test_update_changes_the_setting_and_records_the_user
    setting = create_evm_setting(user_id: 3)

    patch :update, params: { project_id: @project.id, id: setting.id,
                             evmsetting: { basis_hours: 6, etc_method: "method1", region: "us" } }

    assert_redirected_to "/projects/#{@project.id}/evms"
    setting.reload
    assert_equal [6.0, "method1", "us", 2], [setting.basis_hours, setting.etc_method, setting.region, setting.user_id]
  end

  def test_update_with_invalid_values_shows_the_form_again
    setting = create_evm_setting

    patch :update, params: { project_id: @project.id, id: setting.id, evmsetting: { threshold_spi: 1.5 } }

    assert_response :success
    assert_equal 0.9, setting.reload.threshold_spi
  end

  def test_without_the_manage_permission_everything_is_denied
    Role.find(1).remove_permission!(:manage_evmsettings)

    get :new, params: { project_id: @project.id }
    assert_response :forbidden
    assert_no_difference "Evmsetting.count" do
      post :create, params: { project_id: @project.id, evmsetting: setting_params }
    end
    assert_response :forbidden
  end

  private

  def setting_params
    { view_forecast: "1", view_version: "0", view_performance: "1", view_issuelist: "0", basis_hours: 7.5,
      etc_method: "method3", exclude_holidays: "1", region: "us",
      threshold_spi: 0.8, threshold_cpi: 0.7, threshold_cr: 0.6 }
  end
end
