require File.expand_path("evm_calculation_test_helper", __dir__)

# Unit tests for CalculatePv (Planned Value). Uses FakeIssue (see
# evm_calculation_test_helper.rb) instead of a real Issue/ActiveRecord record --
# CalculatePv only ever calls start_date / due_date / estimated_hours /
# fixed_version_id on the issues it is given, so a plain duck-typed double is
# enough as long as due_date is always set (a nil due_date would fall back to
# Version.find(fixed_version_id).effective_date, which needs a real DB record
# and is out of scope for this unit test).
class CalculatePvTest < ActiveSupport::TestCase
  def setup
    # 10h over Jan 1-5 (2h/day), 4h over Jan 3-4 (2h/day)
    @issue1 = FakeIssue.new(Date.new(2026, 1, 1), Date.new(2026, 1, 5), 10.0)
    @issue2 = FakeIssue.new(Date.new(2026, 1, 3), Date.new(2026, 1, 4), 4.0)
  end

  def test_start_date_due_date_and_bac_span_all_issues
    pv = CalculatePv.new(Date.new(2026, 1, 3), [@issue1, @issue2], nil, false)

    assert_equal Date.new(2026, 1, 1), pv.start_date
    assert_equal Date.new(2026, 1, 5), pv.due_date
    assert_equal 14.0, pv.bac
    assert_equal 5, pv.sac
  end

  def test_today_value_is_the_cumulative_pv_on_the_basis_date
    pv = CalculatePv.new(Date.new(2026, 1, 3), [@issue1, @issue2], nil, false)

    # issue1 contributes 2.0/day for Jan1-3 (6.0), issue2 contributes 2.0/day for Jan3 (2.0)
    assert_equal 8.0, pv.today_value
  end

  def test_state_is_within_duration_between_start_and_due_date
    pv = CalculatePv.new(Date.new(2026, 1, 3), [@issue1], nil, false)

    assert_equal :within_duration, pv.state
  end

  def test_state_is_overdue_once_basis_date_passes_due_date
    pv = CalculatePv.new(Date.new(2026, 1, 10), [@issue1], nil, false)

    assert_equal :overdue, pv.state
    assert_equal 0, pv.rest_days
  end

  def test_state_is_before_plan_when_basis_date_precedes_start_date
    pv = CalculatePv.new(Date.new(2025, 12, 1), [@issue1], nil, false)

    assert_equal :before_plan, pv.state
    assert_equal 0, pv.today_es(0)
  end

  def test_today_es_returns_working_days_up_to_where_cumulative_pv_reaches_the_ev_value
    pv = CalculatePv.new(Date.new(2026, 1, 3), [@issue1, @issue2], nil, false)

    assert_equal 3, pv.today_es(8.0)
  end

  def test_no_issues_falls_back_to_the_basis_date_with_a_zero_bac
    pv = CalculatePv.new(Date.new(2026, 1, 10), [], nil, false)

    assert_equal Date.new(2026, 1, 10), pv.start_date
    assert_equal 0.0, pv.bac
  end
end
