require File.expand_path("evms_api_test_helper", __dir__)

# REST API of the EVM values: the baseline option and the values.
class EvmsApiTest < Redmine::ApiTest::Base
  include EvmsApiTestSupport

  def test_the_latest_baseline_is_used_when_the_option_is_not_given
    create_baseline("Old plan", Time.utc(2026, 1, 1), [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 40]])
    latest = create_baseline("Latest plan", Time.utc(2026, 1, 2),
                             [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 80]])

    get evms_path(basis_date: "2026-01-08"), headers: credentials("jsmith")

    assert_response :success
    assert_equal "application/json", response.media_type
    evm = response.parsed_body["evm"]
    assert_equal({ "id" => @project.id, "name" => "EVM scenario" }, evm["project"])
    assert_equal "2026-01-08", evm["basis_date"]
    assert_equal latest.id, evm["baseline"]["id"]
    assert_equal "Latest plan", evm["baseline"]["subject"]
    assert_equal "2026-01-02T00:00:00Z", evm["baseline"]["created_on"]
    assert_in_delta 64.0, evm["hours"]["pv"]
    assert_in_delta 80.0, evm["hours"]["bac"]
  end

  def test_the_latest_baseline_option
    latest = create_baseline("Latest plan", Time.utc(2026, 1, 2),
                             [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 80]])

    get evms_path(basis_date: "2026-01-08", baseline: "latest"), headers: credentials("jsmith")

    assert_response :success
    evm = response.parsed_body["evm"]
    assert_equal latest.id, evm["baseline"]["id"]
    assert_in_delta 64.0, evm["hours"]["pv"]
  end

  def test_no_baseline_is_used_with_the_none_option
    create_baseline("Latest plan", Time.utc(2026, 1, 2), [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 80]])

    get evms_path(basis_date: "2026-01-08", baseline: "none"), headers: credentials("jsmith")

    assert_response :success
    evm = response.parsed_body["evm"]
    assert_nil evm["baseline"]
    assert_current_issue_values evm
  end

  def test_no_baseline_is_used_when_the_project_has_none
    get evms_path(basis_date: "2026-01-08", baseline: "latest"), headers: credentials("jsmith")

    assert_response :success
    evm = response.parsed_body["evm"]
    assert_nil evm["baseline"]
    assert_current_issue_values evm
  end

  def test_the_values
    get evms_path(basis_date: "2026-01-08"), headers: credentials("jsmith")

    assert_response :success
    evm = response.parsed_body["evm"]
    assert_equal 8, evm["working_hours"]
    assert_equal false, evm["no_data"]
    assert_equal "progress", evm["ev_state"]
    assert_equal "within_duration", evm["plan_state"]
    assert_nil evm["finished_date"]
    assert_equal "2026-01-05", evm["plan_start_date"]
    assert_equal "2026-01-16", evm["plan_due_date"]
    assert_equal HOURS_VALUES, evm["hours"].keys
    # SV = EV - PV, CV = EV - AC, SPI = EV / PV, CPI = EV / AC
    assert_in_delta(-12.0, evm["hours"]["sv"])
    assert_in_delta 4.0, evm["hours"]["cv"]
    assert_in_delta 0.63, evm["hours"]["spi"]
    assert_in_delta 1.25, evm["hours"]["cpi"]
    assert_in_delta 7.5, evm["days"]["bac"] # 60h / 8h
    assert_in_delta 2.5, evm["days"]["ev"]
    assert_equal EARNED_SCHEDULE_VALUES, evm["earned_schedule"].keys
  end

  def test_the_values_are_the_ones_of_the_page
    get evms_path(basis_date: "2026-01-08", baseline: "none"), headers: credentials("jsmith")
    evm = response.parsed_body["evm"]

    page_evm = page_project_evm(basis_date: "2026-01-08", no_use_baseline: "1")
    assert_not_nil evm
    [[:hours, 1], [:days, 8]].each do |unit, hours|
      assert_in_delta page_evm.bac(hours), evm[unit.to_s]["bac"]
      assert_in_delta page_evm.today_ac(hours), evm[unit.to_s]["ac"]
      assert_in_delta page_evm.eac(hours), evm[unit.to_s]["eac"]
      assert_in_delta page_evm.tcpi(hours), evm[unit.to_s]["tcpi"]
    end
    assert_equal page_evm.today_es, evm["earned_schedule"]["es"]
    assert_in_delta page_evm.teac, evm["earned_schedule"]["teac"]
  end

  def test_the_forecast_values_are_not_given_when_the_project_is_finished
    finish_scenario

    get evms_path(basis_date: "2026-01-20", baseline: "none"), headers: credentials("jsmith")

    assert_response :success
    evm = response.parsed_body["evm"]
    assert_equal "finished", evm["ev_state"]
    assert evm["finished_date"]
    %w[hours days].each do |unit|
      FORECAST_VALUES.each { |key| assert_nil evm[unit][key], "#{unit} #{key}" }
    end
    %w[teac tvac].each { |key| assert_nil evm["earned_schedule"][key], key }
  end

  def test_xml
    get evms_path(format: "xml", basis_date: "2026-01-08", baseline: "none"), headers: credentials("jsmith")

    assert_response :success
    assert_equal "application/xml", response.media_type
    assert_select "evm>project[id=?][name=?]", @project.id.to_s, "EVM scenario"
    assert_select "evm>basis_date", text: "2026-01-08"
    assert_select "evm>baseline", text: ""
    assert_select "evm>ev_state", text: "progress"
    assert_select "evm>plan_state", text: "within_duration"
    assert_select "evm>hours>bac", text: "60.0"
    assert_select "evm>days>bac", text: "7.5"
  end

  def test_a_project_without_issues_has_no_data
    Issue.where(project_id: @project.id).find_each(&:destroy)

    get evms_path(basis_date: "2026-01-08"), headers: credentials("jsmith")

    assert_response :success
    evm = response.parsed_body["evm"]
    assert_equal true, evm["no_data"]
    assert_not evm.key?("hours")
  end
end
