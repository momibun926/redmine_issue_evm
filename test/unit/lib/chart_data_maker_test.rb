require File.expand_path("evm_calculation_test_helper", __dir__)

# Unit tests for ChartDataMaker (lib/chart_data_maker.rb).
#
# ChartDataMaker used to be `include`d into BaseevmController like the
# other lib/ modules; it is now called explicitly as
# ChartDataMaker.evm_chart_data(evm) / ChartDataMaker.performance_chart_data(evm)
# (see EvmsController#create_evm_data and EvmBreakdownController#create_evm_data,
# and the current-state analysis doc, section 12). This test exists mainly
# to pin down that the module-function conversion didn't change behavior --
# every value here was produced by actually running this code (see the
# commit message for how) against a real CalculateEvm built the same way
# CalculateEvmTest builds one.
class ChartDataMakerTest < ActiveSupport::TestCase
  def test_evm_chart_data_for_a_finished_project_has_no_forecast_series
    # Same fixture as CalculateEvmTest: closes on day 4, basis date day 10 ->
    # already finished, so CalculateEvm forces forecast off regardless of
    # the :forecast option, and the forecast series stay empty.
    issue = FakeIssue.new(Date.new(2026, 1, 1), Date.new(2026, 1, 5), 10.0, 100,
                          Time.utc(2026, 1, 4, 3, 0, 0), false,
                          [FakeJournal.new(Time.utc(2026, 1, 2, 1, 0, 0), 60)])
    costs = { Date.new(2026, 1, 2) => 5.0, Date.new(2026, 1, 4) => 3.0 }
    options = { basis_date: Date.new(2026, 1, 10), working_hours: 8, forecast: true,
                etc_method: "method2", exclude_holiday: false, region: nil }
    evm = CalculateEvmLogic::CalculateEvm.new(nil, [issue], costs, options)

    chart = ChartDataMaker.evm_chart_data(evm)

    assert_equal %i[labels pv_actual pv_daily pv_baseline ac ev bac eac eac_daily ac_forecast ev_forecast],
                 chart.keys
    assert_equal 6, chart[:labels].length
    assert_equal "[2.0,4.0,6.0,8.0,10.0,null]", chart[:pv_actual]
    assert_equal "[null,6.0,null,10.0,null,null]", chart[:ev]
    assert_equal "[null,5.0,null,8.0,null,null]", chart[:ac]
    # finished_date present -> CalculateEvm#initialize forces @forecast = false,
    # so evm_chart_data's `if evm.forecast` branch never runs and these stay empty.
    assert_equal "[]", chart[:bac]
    assert_equal "[]", chart[:eac]
  end

  def test_evm_chart_data_for_an_unfinished_project_with_forecast_on_fills_the_forecast_series
    # Not finished (done_ratio 40, no closed_on) and basis date is before the
    # due date, so the `if evm.forecast` branch in evm_chart_data actually runs.
    issue = FakeIssue.new(Date.new(2026, 1, 1), Date.new(2026, 1, 5), 10.0, 40,
                          nil, false, [FakeJournal.new(Time.utc(2026, 1, 2, 1, 0, 0), 40)])
    costs = { Date.new(2026, 1, 2) => 3.0 }
    options = { basis_date: Date.new(2026, 1, 3), working_hours: 8, forecast: true,
                etc_method: "method2", exclude_holiday: false, region: nil }
    evm = CalculateEvmLogic::CalculateEvm.new(nil, [issue], costs, options)
    assert evm.forecast, "fixture should keep forecast on (project not finished)"

    chart = ChartDataMaker.evm_chart_data(evm)

    assert_equal "[10.0,null,null,null,null,10.0]", chart[:bac]
    assert_equal "[7.5,null,null,null,null,7.5]", chart[:eac]
    assert_equal "[null,null,3.0,null,7.5,null]", chart[:ac_forecast]
    assert_equal "[null,null,4.0,null,10.0,null]", chart[:ev_forecast]
  end

  def test_performance_chart_data_returns_spi_cpi_cr_series
    issue = FakeIssue.new(Date.new(2026, 1, 1), Date.new(2026, 1, 5), 10.0, 100,
                          Time.utc(2026, 1, 4, 3, 0, 0), false,
                          [FakeJournal.new(Time.utc(2026, 1, 2, 1, 0, 0), 60)])
    costs = { Date.new(2026, 1, 2) => 5.0, Date.new(2026, 1, 4) => 3.0 }
    options = { basis_date: Date.new(2026, 1, 10), working_hours: 8, forecast: false,
                etc_method: "method2", exclude_holiday: false, region: nil }
    evm = CalculateEvmLogic::CalculateEvm.new(nil, [issue], costs, options)

    perf = ChartDataMaker.performance_chart_data(evm)

    assert_equal %i[labels spi cpi cr], perf.keys
    assert_equal 6, perf[:labels].length
    assert_equal "[null,1.5,1.67,1.25,null,null]", perf[:spi]
    assert_equal "[null,1.2,1.25,1.25,null,null]", perf[:cpi]
    assert_equal "[null,1.8,2.08,1.56,null,null]", perf[:cr]
  end

  # ---- more scenarios (added before splitting evm_chart_data & co. into
  # smaller methods, to pin their behavior down). The expected series were
  # produced by running the code *before* that split; the hand-checkable
  # parts are noted in the comments.

  def test_evm_chart_data_with_a_baseline_adds_the_baseline_series_and_extends_the_chart
    # baseline: 20h over Jan 1-10 (2h/day); actual plan: 10h over Jan 1-5
    baseline = [FakeIssue.new(Date.new(2026, 1, 1), Date.new(2026, 1, 10), 20.0, 0)]
    issue = FakeIssue.new(Date.new(2026, 1, 1), Date.new(2026, 1, 5), 10.0, 40, nil, false,
                          [FakeJournal.new(Time.utc(2026, 1, 2, 1, 0, 0), 40)])
    costs = { Date.new(2026, 1, 2) => 6.0, Date.new(2026, 1, 3) => 2.0 }
    evm = CalculateEvmLogic::CalculateEvm.new(baseline, [issue], costs, scenario_options(Date.new(2026, 1, 3)))

    chart = ChartDataMaker.evm_chart_data(evm)

    # chart runs to the day after the baseline's due date (Jan 11): 11 days
    assert_equal 11, chart[:labels].length
    assert_equal "[2.0,4.0,6.0,8.0,10.0,12.0,14.0,16.0,18.0,20.0,null]", chart[:pv_baseline]
    assert_equal "[2.0,4.0,6.0,8.0,10.0,null,null,null,null,null,null]", chart[:pv_actual]
    assert_equal "[null,6.0,8.0,null,null,null,null,null,null,null,null]", chart[:ac]
    assert_equal "[null,4.0,4.0,null,null,null,null,null,null,null,null]", chart[:ev]
    # BAC is the baseline's (20h)
    assert_equal "[20.0,null,null,null,null,null,null,null,null,null,20.0]", chart[:bac]
    assert_equal "[null,29.88,40.0,null,null,null,null,null,null,null,null]", chart[:eac_daily]
  end

  def test_evm_chart_data_for_an_overdue_project_forecasts_beyond_the_due_date
    issue = FakeIssue.new(Date.new(2026, 1, 1), Date.new(2026, 1, 5), 10.0, 40, nil, false,
                          [FakeJournal.new(Time.utc(2026, 1, 2, 1, 0, 0), 40)])
    costs = { Date.new(2026, 1, 2) => 6.0, Date.new(2026, 1, 3) => 2.0 }
    evm = CalculateEvmLogic::CalculateEvm.new(nil, [issue], costs, scenario_options(Date.new(2026, 1, 10)))

    chart = ChartDataMaker.evm_chart_data(evm)

    # forecast finish is Jan 12, so the chart runs to Jan 13
    assert_equal 13, chart[:labels].length
    assert_equal "[]", chart[:pv_baseline]
    assert_equal "[null,null,null,null,null,null,null,null,null,8.0,null,20.0,null]", chart[:ac_forecast]
    assert_equal "[null,null,null,null,null,null,null,null,null,4.0,null,10.0,null]", chart[:ev_forecast]
  end

  def test_performance_chart_data_fills_the_days_between_dates_with_values
    # EV/AC only change on Jan 2, 9 and 15; the indicators of the days in
    # between are computed from values interpolated on a straight line.
    issue = FakeIssue.new(Date.new(2026, 1, 1), Date.new(2026, 1, 20), 40.0, 70, nil, false,
                          [FakeJournal.new(Time.utc(2026, 1, 2, 1, 0, 0), 20),
                           FakeJournal.new(Time.utc(2026, 1, 9, 1, 0, 0), 50),
                           FakeJournal.new(Time.utc(2026, 1, 15, 1, 0, 0), 70)])
    costs = { Date.new(2026, 1, 2) => 4.0, Date.new(2026, 1, 9) => 9.0, Date.new(2026, 1, 15) => 5.0 }
    evm = CalculateEvmLogic::CalculateEvm.new(nil, [issue], costs, scenario_options(Date.new(2026, 1, 16)))

    perf = ChartDataMaker.performance_chart_data(evm)
    chart = ChartDataMaker.evm_chart_data(evm)

    assert_equal 22, perf[:labels].length
    assert_equal "[null,2.0,1.67,1.5,1.4,1.33,1.29,1.25,1.11,1.08,1.05,1.03,1.02,1.0,0.93,0.88,null,null,null,null,null,null]",
                 perf[:spi]
    assert_equal "[null,2.0,1.82,1.71,1.65,1.6,1.57,1.54,1.54,1.54,1.55,1.55,1.55,1.56,1.56,1.56,null,null,null,null,null,null]",
                 perf[:cpi]
    # EV: 20% / 50% / 70% of 40h
    assert_equal "[null,8.0,null,null,null,null,null,null,20.0,null,null,null,null,null,28.0,28.0,null,null,null,null,null,null]",
                 chart[:ev]
  end

  def test_module_function_keeps_these_methods_private_if_ever_mixed_in
    # Documents the module_function behavior the file comment relies on:
    # ChartDataMaker.evm_chart_data(...) works, but if some future class
    # `include`s ChartDataMaker again, the method must stay a private
    # instance method there (matching every other lib/ module's convention
    # of being called without an explicit receiver).
    host_class = Class.new { include ChartDataMaker }

    assert_raises(NoMethodError) { host_class.new.evm_chart_data(nil) }
  end

  private

  def scenario_options(basis_date)
    { basis_date: basis_date, working_hours: 8, forecast: true,
      etc_method: "method2", exclude_holiday: false, region: nil }
  end
end
