require File.expand_path("evm_calculation_test_helper", __dir__)

# Integration-style smoke test for CalculateEvm (lib/calculate_evm_logic.rb), the class
# that wires CalculateAc + CalculatePv + CalculateEv together and derives the actual EVM
# indicators (BAC, SV, CV, SPI, CPI, ...). CalculateAc/CalculatePv/CalculateEv each have
# their own focused unit tests; this one exists to catch regressions in how CalculateEvm
# combines their results and to give the indicator formulas at least one worked example
# with hand-checkable numbers.
class CalculateEvmTest < ActiveSupport::TestCase
  def test_evm_indicators_for_a_single_on_schedule_on_budget_issue
    # Plan: 10h over Jan 1-5 (2h/day). Actual: 60% done by Jan 2, closed Jan 4.
    # Actual cost: 5h on Jan 2, 3h on Jan 4 (8h total, same as EV).
    issue = FakeIssue.new(Date.new(2026, 1, 1), Date.new(2026, 1, 5), 10.0, 100,
                          Time.utc(2026, 1, 4, 3, 0, 0), false,
                          [FakeJournal.new(Time.utc(2026, 1, 2, 1, 0, 0), 60)])
    costs = { Date.new(2026, 1, 2) => 5.0, Date.new(2026, 1, 4) => 3.0 }
    options = { basis_date: Date.new(2026, 1, 10), working_hours: 8, forecast: false,
                etc_method: "method2", exclude_holiday: false, region: nil }

    evm = CalculateEvmLogic::CalculateEvm.new(nil, [issue], costs, options)

    # BAC/PV/EV are all 10h -> 1.25 days at 8h/day, rounded to 1 decimal place
    assert_equal 1.3, evm.bac(8)
    assert_equal 1.3, evm.today_pv(8)
    assert_equal 1.3, evm.today_ev(8)
    assert_equal 1.0, evm.today_ac(8)
    assert_equal 0.0, evm.today_sv(8)
    assert_equal 0.3, evm.today_cv(8)
    assert_equal 1.0, evm.today_spi(8)
    assert_equal 1.3, evm.today_cpi(8)
    assert_equal [:finished], evm.project_state
  end
end
