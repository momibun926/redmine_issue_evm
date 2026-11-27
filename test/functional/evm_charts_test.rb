require File.expand_path("evm_functional_test_helper", __dir__)

# The charts are drawn in the browser by the evm-chart Stimulus controller
# (assets/javascripts/evm_chart_controller.js) with Redmine's Chart.js. These
# tests check what the server gives it: the markup and the data as JSON.
module EvmChartAssertions
  # Data of the charts of a kind on the page
  def chart_data(kind)
    css_select("div[data-controller='evm-chart'][data-evm-chart-kind-value='#{kind}']").map do |chart|
      assert_equal 1, chart.css("canvas[data-evm-chart-target='canvas']").size
      JSON.parse(chart.at_css("template[data-evm-chart-target='data']").inner_html)
    end
  end

  def assert_chart_script_loaded
    assert_select "script[type='module'][src*='plugin_assets/redmine_issue_evm/evm_chart_controller']", 1
    assert_select "script[src*='Chart.bundle']", 0
    assert_select "script[src*='chartjs-plugin-annotation']", 0
  end
end

class EvmChartsTest < Redmine::ControllerTest
  tests EvmsController
  include EvmFunctionalTestSupport
  include EvmChartAssertions

  def setup
    sign_in_as_project_member
    create_evm_setting
  end

  def test_the_evm_chart_has_the_dates_the_series_and_the_basis_date
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    assert_response :success
    assert_chart_script_loaded
    data = chart_data("project").sole
    assert_equal "2026-01-05", data["labels"].first
    assert_equal 15, data["labels"].size
    expected = controller_ivar(:evm_chart_data).except(:labels).transform_keys(&:to_s)
    assert_equal JSON.parse(expected.to_json), data["series"]
    assert_equal "2026-01-08", data["basisDate"]
    assert_equal I18n.t(:label_basis_date), data["basisDateLabel"]
  end

  def test_the_performance_chart_has_spi_cpi_and_cr
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    data = chart_data("performance").sole
    assert_equal %w[cpi cr spi], data["series"].keys.sort
    assert_equal data["labels"].size, data["series"]["spi"].size
  end

  def test_without_the_performance_option_there_is_no_performance_chart
    Evmsetting.where(project_id: @project.id).update_all(view_performance: false) # rubocop:disable Rails/SkipsModelValidations

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    assert_empty chart_data("performance")
    assert_equal 1, chart_data("project").size
  end

  def test_a_finished_project_draws_the_line_at_the_finished_date
    finish_scenario_project

    get :index, params: { project_id: @project.id, basis_date: "2026-01-31" }

    data = chart_data("project").sole
    assert_equal controller_ivar(:project_evm).finished_date.iso8601, data["basisDate"]
    assert_equal I18n.t(:label_finished_date), data["basisDateLabel"]
  end

  private

  def finish_scenario_project
    closed = IssueStatus.where(is_closed: true).first
    Issue.where(project_id: @project.id).find_each do |issue|
      update_issue_columns(issue, status_id: closed.id, done_ratio: 100, closed_on: Time.utc(2026, 1, 16, 3))
    end
  end
end

class EvmassigneesChartsTest < Redmine::ControllerTest
  tests EvmassigneesController
  include EvmFunctionalTestSupport
  include EvmChartAssertions

  def setup
    sign_in_as_project_member
    create_evm_setting
  end

  def test_each_assignee_has_a_chart_with_the_working_hours
    update_issue_columns(@issue2, assigned_to_id: 3)

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", selected_assignee_id: %w[2 3] }

    assert_response :success
    assert_chart_script_loaded
    charts = chart_data("assignee")
    assert_equal 2, charts.size
    assert_equal [8.0, I18n.t(:estimated_working_hours)], [charts.first["workingHours"], charts.first["pvDailyLabel"]]
    assert_equal "2026-01-08", charts.first["basisDate"]
    assert_equal JSON.parse(controller_ivar(:evm_chart_data)["2"][:pv_daily].to_json), charts.first["series"]["pv_daily"]
  end
end

class EvmversionsChartsTest < Redmine::ControllerTest
  tests EvmversionsController
  include EvmFunctionalTestSupport
  include EvmChartAssertions

  def setup
    sign_in_as_project_member
    create_evm_setting
  end

  def test_a_version_has_a_basic_chart
    version_id = @issue1.fixed_version_id

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", selected_version_id: [version_id] }

    assert_response :success
    data = chart_data("basic").sole
    assert_equal %w[pv_actual ev ac].sort, (data["series"].keys & %w[pv_actual ev ac]).sort
    assert_equal "2026-01-08", data["basisDate"]
  end
end
