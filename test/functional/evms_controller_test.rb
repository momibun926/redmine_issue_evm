require File.expand_path("evm_functional_test_helper", __dir__)

# Functional tests of EvmsController#index, the main EVM page.
#
# The expected numbers come from the scenario project in
# EvmFunctionalTestSupport (see there for its issues and spent time):
# on Thu 2026-01-08 the plan is 4 days x 8h = 32h, issue 1 is 50% done
# (20h earned), and 16h have been spent.
class EvmsControllerTest < Redmine::ControllerTest
  include EvmFunctionalTestSupport

  def setup
    sign_in_as_project_member
  end

  def test_without_an_evm_setting_it_redirects_to_the_new_setting_page
    get :index, params: { project_id: @project.id }

    assert_redirected_to "/projects/#{@project.id}/evmsettings/new"
  end

  def test_shows_the_evm_page_for_a_project_with_a_setting
    create_evm_setting

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    assert_response :success
    assert_select "div#content"
    assert_not controller_ivar(:no_data)
  end

  def test_basis_date_param_sets_the_date_the_evm_is_calculated_for
    create_evm_setting

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    assert_equal Date.new(2026, 1, 8), controller_ivar(:cfg_param)[:basis_date]
    assert_equal Date.new(2026, 1, 8), controller_ivar(:project_evm).basis_date
  end

  def test_basis_date_defaults_to_today
    create_evm_setting

    travel_to Time.utc(2026, 1, 8, 12, 0, 0) do
      get :index, params: { project_id: @project.id }
    end

    assert_equal Date.new(2026, 1, 8), controller_ivar(:cfg_param)[:basis_date]
  end

  def test_a_blank_basis_date_is_treated_as_today
    create_evm_setting

    travel_to Time.utc(2026, 1, 8, 12, 0, 0) do
      get :index, params: { project_id: @project.id, basis_date: "" }
    end

    assert_response :success
    assert_equal Date.new(2026, 1, 8), controller_ivar(:cfg_param)[:basis_date]
  end

  def test_the_report_param_holds_the_evm_values_of_the_basis_date
    create_evm_setting

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    assert_equal({ status_date: Date.new(2026, 1, 8), baseline_id: nil, bac: 60.0, pv: 32.0, ev: 20.0,
                   ac: 16.0, sv: -12.0, cv: 4.0, working_hours: 8.0 },
                 controller_ivar(:report_param))
  end

  def test_the_cfg_param_is_built_from_the_evm_setting
    create_evm_setting(etc_method: "method3", basis_hours: 7.5, threshold_spi: 0.8, view_forecast: false)

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", display_explanation: "1" }

    cfg_param = controller_ivar(:cfg_param)
    assert_equal "method3", cfg_param[:etc_method]
    assert_equal 7.5, cfg_param[:working_hours]
    assert_equal 0.8, cfg_param[:limit_spi]
    assert_equal false, cfg_param[:forecast]
    assert_equal "jp", cfg_param[:region]
    assert_equal "1", cfg_param[:display_explanation]
  end

  def test_project_metrics_counts_and_baseline_variance
    create_evm_setting

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    metrics = controller_ivar(:project_metrics)
    assert_equal 2, metrics[:total_issue_ids]
    assert_equal 2, metrics[:target_issue_ids]
    assert_equal Date.new(2026, 1, 5), metrics[:plan_start_date]
    assert_equal Date.new(2026, 1, 16), metrics[:plan_due_date]
    assert_equal({ "Release 1" => 1 }, controller_ivar(:count_version_list))
    assert_equal({ "Bug" => 1, "Feature request" => 1 }, controller_ivar(:count_tracker_list))
    assert_equal [2], controller_ivar(:count_assignee_list).keys.map(&:id)
    assert_equal({}, controller_ivar(:baseline_variance))
  end

  def test_incomplete_issues_are_the_overdue_open_issues_when_the_setting_displays_them
    create_evm_setting

    get :index, params: { project_id: @project.id, basis_date: "2026-01-20" }

    assert_equal [@issue1.id], controller_ivar(:incomplete_issues).map(&:id)
    assert_not controller_ivar(:no_data_incomplete_issues)
  end

  def test_incomplete_issues_are_not_collected_when_the_setting_hides_them
    create_evm_setting(view_issuelist: false)

    get :index, params: { project_id: @project.id, basis_date: "2026-01-20" }

    assert_nil controller_ivar(:incomplete_issues)
    assert_nil controller_ivar(:no_data_incomplete_issues)
  end

  def test_the_chart_data_covers_the_plan_from_start_to_the_day_after_the_end
    create_evm_setting

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    chart = controller_ivar(:evm_chart_data)
    assert_equal 15, chart[:labels].length # 2026-01-05 .. 2026-01-19
    assert_equal "[8.0,16.0,24.0,32.0,40.0,null,null,44.0,48.0,52.0,56.0,60.0,null,null,null]", chart[:pv_actual]
    assert_equal "[null,8.0,16.0,16.0,null,null,null,null,null,null,null,null,null,null,null]", chart[:ac]
    assert_equal "[null,null,20.0,20.0,null,null,null,null,null,null,null,null,null,null,null]", chart[:ev]
    assert_equal 15, JSON.parse(controller_ivar(:performance_chart_data)[:spi]).length
  end

  # ---- baseline ----------------------------------------------------------

  def test_the_latest_baseline_is_selected_by_default
    create_evm_setting
    create_baseline("old", Time.utc(2026, 1, 1), [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 40.0]])
    latest = create_baseline("latest", Time.utc(2026, 1, 3),
                             [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 30.0],
                              [@issue2, Date.new(2026, 1, 12), Date.new(2026, 1, 14), 10.0]])

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    assert_equal %w[latest old], controller_ivar(:selectable_baseline).map(&:subject)
    assert_equal latest.id, controller_ivar(:cfg_param)[:baseline_id]
    assert_equal latest.id, controller_ivar(:report_param)[:baseline_id]
    evm = controller_ivar(:project_evm)
    assert_equal 40.0, evm.bac # the baseline's BAC (30h + 10h)
    assert_equal 60.0, evm.pv_actual.bac
    assert_equal %i[bac due_date schedule], controller_ivar(:baseline_variance).keys
  end

  def test_the_baseline_param_selects_another_baseline
    create_evm_setting
    old = create_baseline("old", Time.utc(2026, 1, 1), [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 40.0]])
    create_baseline("latest", Time.utc(2026, 1, 3), [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 30.0]])

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", evmbaseline_id: old.id }

    assert_equal old.id.to_s, controller_ivar(:cfg_param)[:baseline_id]
    assert_equal 40.0, controller_ivar(:project_evm).bac
  end

  def test_no_use_baseline_param_calculates_without_a_baseline
    create_evm_setting
    create_baseline("latest", Time.utc(2026, 1, 3), [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 30.0]])

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", no_use_baseline: "1" }

    assert_nil controller_ivar(:cfg_param)[:baseline_id]
    assert_equal "1", controller_ivar(:cfg_param)[:no_use_baseline]
    assert_nil controller_ivar(:project_evm).pv_baseline
    assert_equal 60.0, controller_ivar(:project_evm).bac
  end

  # ---- CSV export --------------------------------------------------------

  def test_csv_export_sends_the_evm_as_a_csv_file
    create_evm_setting

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", format: "csv" }

    assert_response :success
    assert_match %r{\Atext/csv}, response.media_type
    assert_includes response.headers["Content-Type"], "header=present"
    assert_match(/filename="?evm_EVM scenario_#{Date.current}\.csv"?/, response.headers["Content-Disposition"])
    assert_equal controller_ivar(:project_evm).to_csv, response.body
    assert_match(/^PV,/, response.body)
  end

  # ---- access control ----------------------------------------------------

  def test_anonymous_users_are_asked_to_log_in
    create_evm_setting
    @request.session[:user_id] = nil

    get :index, params: { project_id: @project.id }

    assert_response :redirect
    assert_match %r{/login}, response.location
  end

  def test_a_user_who_is_not_a_member_is_denied
    create_evm_setting
    @request.session[:user_id] = 3

    get :index, params: { project_id: @project.id }

    assert_response :forbidden
  end

  def test_a_member_without_the_view_permission_is_denied
    create_evm_setting
    Role.find(1).remove_permission!(:view_evms)

    get :index, params: { project_id: @project.id }

    assert_response :forbidden
  end

  def test_an_unknown_project_is_not_found
    get :index, params: { project_id: "no-such-project" }

    assert_response :not_found
  end
end
