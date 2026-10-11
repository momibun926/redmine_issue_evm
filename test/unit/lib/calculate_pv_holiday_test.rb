require File.expand_path("evm_calculation_test_helper", __dir__)

# CalculatePv with exclude_holiday on/off. calculate_pv_test.rb only ever runs
# with exclude_holiday = false; this covers the other branch of
# EvmUtil#working_days as CalculatePv uses it (spreading the estimate over
# working days only, and counting SAC / rest days in working days).
#
# Mon Jun 15 .. Sun Jun 21, 2026 is used because nothing in that week is a
# public holiday in :jp, so the result only depends on the weekend rule.
class CalculatePvHolidayTest < ActiveSupport::TestCase
  def setup
    @issue = FakeIssue.new(Date.new(2026, 6, 15), Date.new(2026, 6, 21), 10.0)
  end

  def test_estimate_is_spread_over_working_days_only_when_holidays_are_excluded
    pv = CalculatePv.new(Date.new(2026, 6, 19), [@issue], :jp, true)

    # 10h over 5 working days = 2h/day, nothing on Sat/Sun
    assert_equal 5, pv.sac
    assert_equal 10.0, pv.bac
    assert_equal 10.0, pv.today_value
    assert_equal Date.new(2026, 6, 15), pv.start_date
    assert_equal Date.new(2026, 6, 19), pv.cumulative.keys.max
  end

  def test_estimate_is_spread_over_all_days_when_holidays_are_not_excluded
    pv = CalculatePv.new(Date.new(2026, 6, 19), [@issue], :jp, false)

    assert_equal 7, pv.sac
    assert_equal 10.0, pv.bac
    assert_equal Date.new(2026, 6, 21), pv.due_date
    # 5 of the 7 days (10/7 h each) have elapsed on Fri Jun 19
    assert_in_delta 10.0 * 5 / 7, pv.today_value, 1e-9
  end

  def test_rest_days_count_only_working_days_when_holidays_are_excluded
    # Wed Jun 17: remaining Wed..Sun with the weekend excluded = Wed, Thu, Fri
    pv = CalculatePv.new(Date.new(2026, 6, 17), [@issue], :jp, true)

    assert_equal 3, pv.rest_days
  end
end
