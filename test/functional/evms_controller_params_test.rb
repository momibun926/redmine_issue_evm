require File.expand_path("evm_functional_test_helper", __dir__)

# Functional tests of how EvmsController#index reads the basis_date and
# evmbaseline_id request parameters when they are blank or unusable.
class EvmsControllerParamsTest < Redmine::ControllerTest
  include EvmFunctionalTestSupport

  tests EvmsController

  def setup
    sign_in_as_project_member
  end

  def test_a_blank_basis_date_is_treated_as_today
    create_evm_setting

    travel_to Time.utc(2026, 1, 8, 12, 0, 0) do
      get :index, params: { project_id: @project.id, basis_date: "" }
    end

    assert_response :success
    assert_equal Date.new(2026, 1, 8), controller_ivar(:cfg_param)[:basis_date]
  end

  def test_a_basis_date_that_is_not_a_date_is_treated_as_today
    create_evm_setting

    %w[abc 2026-02-30].each do |value|
      travel_to Time.utc(2026, 1, 8, 12, 0, 0) do
        get :index, params: { project_id: @project.id, basis_date: value }
      end

      assert_response :success
      assert_equal Date.new(2026, 1, 8), controller_ivar(:cfg_param)[:basis_date], value
    end
  end

  def test_a_basis_date_sent_as_a_list_is_treated_as_today
    create_evm_setting

    travel_to Time.utc(2026, 1, 8, 12, 0, 0) do
      get :index, params: { project_id: @project.id, basis_date: ["2026-01-05"] }
    end

    assert_response :success
    assert_equal Date.new(2026, 1, 8), controller_ivar(:cfg_param)[:basis_date]
  end

  def test_an_unknown_baseline_id_is_not_found
    create_evm_setting

    [Evmbaseline.maximum(:id).to_i + 1, "abc", "99999999999999999999"].each do |value|
      get :index, params: { project_id: @project.id, basis_date: "2026-01-08", evmbaseline_id: value }

      assert_response :not_found, value.to_s
    end
  end

  def test_a_baseline_of_another_project_is_not_found
    create_evm_setting
    other = create_baseline("other project", Time.utc(2026, 1, 2), [], Project.find(1))

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", evmbaseline_id: other.id }

    assert_response :not_found
  end

  def test_a_blank_baseline_id_calculates_without_a_baseline
    create_evm_setting
    create_baseline("latest", Time.utc(2026, 1, 3), [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 30.0]])

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", evmbaseline_id: "" }

    assert_response :success
    assert_nil controller_ivar(:project_evm).pv_baseline
    assert_equal 60.0, controller_ivar(:project_evm).bac
  end
end
