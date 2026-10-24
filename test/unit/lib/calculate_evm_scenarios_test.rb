require File.expand_path("evm_calculation_test_helper", __dir__)

# Scenario tests for CalculateEvm (lib/calculate_evm_logic.rb), complementing
# calculate_evm_test.rb (which only covers one finished, on-budget project).
#
# Common fixture: one 10h issue planned Jan 1-5 2026 (2h/day, weekends not
# excluded). Open issue, 40% done on Jan 2 (EV = 4h), spent 6h on Jan 2 and
# 2h on Jan 3 (AC = 8h). The expected numbers were obtained by running
# lib/calculate_evm_logic.rb itself and then re-derived by hand (comments).
class CalculateEvmScenariosTest < ActiveSupport::TestCase
  def setup
    @costs = { Date.new(2026, 1, 2) => 6.0, Date.new(2026, 1, 3) => 2.0 }
  end

  # open 10h issue, 40% done on Jan 2
  def in_progress_issue(done_ratio = 40, journals = nil)
    journals ||= [FakeJournal.new(Time.utc(2026, 1, 2, 1, 0, 0), 40)]
    FakeIssue.new(Date.new(2026, 1, 1), Date.new(2026, 1, 5), 10.0, done_ratio, nil, false, journals)
  end

  def options(basis_date, etc_method = "method2", forecast: true)
    { basis_date: basis_date, working_hours: 8, forecast: forecast,
      etc_method: etc_method, exclude_holiday: false, region: nil }
  end

  def build(issue, basis_date, costs = @costs, etc_method = "method2", baselines = nil)
    CalculateEvmLogic::CalculateEvm.new(baselines, [issue], costs, options(basis_date, etc_method))
  end

  # ---- in progress, within the planned duration (basis date Jan 3) -------

  def test_in_progress_project_value_indicators
    evm = build(in_progress_issue, Date.new(2026, 1, 3))

    assert_equal 10.0, evm.bac
    assert_equal 5, evm.sac
    assert_equal 40.0, evm.complete_ev
    assert_equal 6.0, evm.today_pv   # 2h x 3 days
    assert_equal 4.0, evm.today_ev   # 40% of 10h
    assert_equal 8.0, evm.today_ac
    assert_equal(-2.0, evm.today_sv) # EV - PV
    assert_equal(-4.0, evm.today_cv) # EV - AC
    assert_equal %i[progress within_duration], evm.project_state
    assert_nil evm.finished_date
  end

  def test_in_progress_project_ratio_indicators
    evm = build(in_progress_issue, Date.new(2026, 1, 3))

    assert_equal 0.67, evm.today_spi # 4 / 6
    assert_equal 0.5, evm.today_cpi  # 4 / 8
    assert_equal 0.34, evm.today_cr  # 0.67 * 0.5, rounded
    assert_equal 3.0, evm.tcpi       # (10 - 4) / (10 - 8)
  end

  def test_in_progress_project_time_based_indicators
    evm = build(in_progress_issue, Date.new(2026, 1, 3))

    assert_equal 2, evm.today_es     # PV first exceeds EV (4h) after 2 days
    assert_equal 3, evm.today_at     # Jan 1..3
    assert_equal(-1, evm.today_tv)   # ES - AT
    assert_equal 0.67, evm.today_tpi # 2 / 3
    assert_equal 7, evm.teac         # SAC / TPI = 5 / 0.67
    assert_equal(-2, evm.tvac)       # SAC - TEAC
  end

  def test_in_progress_project_in_other_units_of_hours_per_day
    evm = build(in_progress_issue, Date.new(2026, 1, 3))

    # the same project expressed in 8h days
    assert_equal 1.3, evm.bac(8)
    assert_equal 0.8, evm.today_pv(8)
    assert_equal 0.5, evm.today_ev(8)
    assert_equal 1.0, evm.today_ac(8)
  end

  # ---- ETC / EAC / VAC depend on the ETC method --------------------------

  def test_etc_eac_vac_follow_the_selected_etc_method
    results = %w[method1 method2 method3].map do |method|
      evm = build(in_progress_issue, Date.new(2026, 1, 3), @costs, method)
      [method, evm.etc, evm.eac, evm.vac]
    end

    # remaining work (BAC - EV) = 6h divided by 1.0 / CPI(0.5) / CR(0.34)
    assert_equal [["method1", 6.0, 14.0, -4.0],
                  ["method2", 12.0, 20.0, -10.0],
                  ["method3", 17.6, 25.6, -15.6]], results
  end

  def test_an_unknown_etc_method_falls_back_to_the_cpi_based_calculation
    evm = build(in_progress_issue, Date.new(2026, 1, 3), @costs, "no_such_method")

    assert_equal 0.5, evm.etc_div_value
    assert_equal 12.0, evm.etc
  end

  def test_etc_is_zero_when_there_is_nothing_to_divide_by
    # no work done and no cost yet -> CPI is 0, so ETC/EAC are reported as 0
    evm = build(in_progress_issue(0, []), Date.new(2026, 1, 3), {})

    assert_equal 0.0, evm.etc
    assert_equal 0.0, evm.eac
  end

  # ---- forecast_finish_date / delay --------------------------------------

  def test_forecast_finish_date_within_duration_adds_the_remaining_days_to_the_due_date
    evm = build(in_progress_issue, Date.new(2026, 1, 3))

    # rest days = ((6 - 4) / 0.67 / 8h).round = 0, so the planned due date stands
    assert_equal Date.new(2026, 1, 5), evm.forecast_finish_date
    assert_equal 0, evm.delay
  end

  def test_forecast_finish_date_is_the_due_date_when_no_work_has_been_done
    evm = build(in_progress_issue(0, []), Date.new(2026, 1, 3), {})

    assert_equal Date.new(2026, 1, 5), evm.forecast_finish_date
    assert_equal 0.0, evm.today_ev
  end

  def test_forecast_finish_date_is_the_basis_date_when_work_started_before_the_plan
    issue = in_progress_issue(40, [FakeJournal.new(Time.utc(2025, 12, 25, 1, 0, 0), 40)])

    evm = build(issue, Date.new(2025, 12, 28), {})

    assert_equal %i[progress before_plan], evm.project_state
    assert_equal Date.new(2025, 12, 28), evm.forecast_finish_date
    assert_equal(-8, evm.delay)
  end

  def test_forecast_finish_date_for_an_overdue_project_counts_from_the_basis_date
    evm = build(in_progress_issue, Date.new(2026, 1, 10))

    assert_equal %i[progress overdue], evm.project_state
    assert_equal 10.0, evm.today_pv
    assert_equal 0.4, evm.today_spi
    # rest days = ((10 - 4) / 0.4 / 8h).round = 2 -> Jan 10 + 2
    assert_equal Date.new(2026, 1, 12), evm.forecast_finish_date
    assert_equal 7, evm.delay
  end

  # ---- finished project --------------------------------------------------

  def test_finished_project_turns_off_the_forecast_and_returns_the_last_ev_date
    issue = FakeIssue.new(Date.new(2026, 1, 1), Date.new(2026, 1, 5), 10.0, 100,
                          Time.utc(2026, 1, 4, 3, 0, 0), false,
                          [FakeJournal.new(Time.utc(2026, 1, 2, 1, 0, 0), 60)])

    evm = build(issue, Date.new(2026, 1, 10))

    assert_equal [:finished], evm.project_state
    assert_equal Date.new(2026, 1, 4), evm.finished_date
    assert_equal false, evm.forecast
    assert_equal 100.0, evm.complete_ev
    assert_equal Date.new(2026, 1, 4), evm.forecast_finish_date
    assert_equal(-1, evm.delay)
    assert_equal 0.0, evm.etc
    assert_equal 8.0, evm.eac
    assert_equal 2.0, evm.vac
  end

  # ---- baseline ----------------------------------------------------------

  def test_pv_follows_the_baseline_when_one_is_given
    baseline = [FakeIssue.new(Date.new(2026, 1, 1), Date.new(2026, 1, 10), 20.0)]

    evm = build(in_progress_issue, Date.new(2026, 1, 3), @costs, "method2", baseline)

    assert_not_nil evm.pv_baseline
    assert_same evm.pv_baseline, evm.pv
    assert_equal 20.0, evm.bac # baseline BAC, not the actual 10h
    assert_equal 10.0, evm.pv_actual.bac
    assert_equal 10, evm.sac
  end

  def test_pv_follows_the_actual_plan_when_there_is_no_baseline
    evm = build(in_progress_issue, Date.new(2026, 1, 3))

    assert_nil evm.pv_baseline
    assert_same evm.pv_actual, evm.pv
  end

  # ---- CSV export --------------------------------------------------------

  def test_to_csv_has_a_date_row_and_cumulative_pv_ev_ac_rows
    evm = build(in_progress_issue, Date.new(2026, 1, 3))

    rows = parse_csv(evm.to_csv)

    assert_equal 4, rows.length
    assert_equal %w[DATE 2026-01-01 2026-01-02 2026-01-03 2026-01-04 2026-01-05], rows[0]
    # cumulative values: PV exists on every planned day, EV/AC only up to the basis date
    assert_equal ["PV", 2.0, 4.0, 6.0, 8.0, 10.0], numeric_row(rows[1])
    assert_equal ["EV", nil, 4.0, 4.0, nil, nil], numeric_row(rows[2])
    assert_equal ["AC", nil, 6.0, 8.0, nil, nil], numeric_row(rows[3])
  end

  private

  # Redmine's CSV helper picks the column separator (and encoding) from the
  # current locale; read whichever one was used instead of assuming ",".
  def parse_csv(csv)
    lines = csv.split(/\r?\n/)
    separator = lines.first[/\ADATE(.)/, 1]
    lines.map { |line| line.split(separator, -1) }
  end

  def numeric_row(row)
    [row.first] + row.drop(1).map { |cell| cell.empty? ? nil : cell.tr(",", ".").to_f }
  end
end
