require File.expand_path("../../test_helper", __dir__)

# Unit tests for CalculateAc (Actual Cost). This class has no ActiveRecord/DB
# dependency of its own: `costs` is just an enumerable of [date, hours] pairs,
# the same shape IssueDataFetcher#evm_costs / #parent_issue_costs return.
class CalculateAcTest < ActiveSupport::TestCase
  def setup
    @basis_date = Date.new(2026, 1, 10)
  end

  def test_daily_and_cumulative_values
    costs = { Date.new(2026, 1, 5) => 4.0, Date.new(2026, 1, 6) => 4.0, Date.new(2026, 1, 8) => 2.0 }

    ac = CalculateAc.new(@basis_date, costs)

    assert_equal 4.0, ac.daily[Date.new(2026, 1, 5)]
    assert_equal 10.0, ac.cumulative[Date.new(2026, 1, 8)]
    assert_equal 10.0, ac.today_value
  end

  def test_min_and_max_date_come_from_the_cost_data
    costs = { Date.new(2026, 1, 5) => 4.0, Date.new(2026, 1, 8) => 2.0 }

    ac = CalculateAc.new(@basis_date, costs)

    assert_equal Date.new(2026, 1, 5), ac.min_date
    assert_equal Date.new(2026, 1, 8), ac.max_date
  end

  def test_costs_after_the_basis_date_are_excluded_from_cumulative_but_not_from_max_date
    costs = { Date.new(2026, 1, 5) => 4.0, Date.new(2026, 1, 20) => 100.0 }

    ac = CalculateAc.new(@basis_date, costs)

    assert_not ac.cumulative.key?(Date.new(2026, 1, 20))
    assert_equal 4.0, ac.today_value
    assert_equal Date.new(2026, 1, 20), ac.max_date
  end

  def test_no_costs_falls_back_to_basis_date_with_zero_value
    ac = CalculateAc.new(@basis_date, {})

    assert_equal @basis_date, ac.min_date
    assert_equal @basis_date, ac.max_date
    assert_equal 0.0, ac.today_value
  end
end
