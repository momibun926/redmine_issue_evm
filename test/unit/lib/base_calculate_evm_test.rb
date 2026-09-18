require File.expand_path("../../test_helper", __dir__)

# Unit tests for BaseCalculateEvm, the shared base class behind CalculateAc,
# CalculatePv and CalculateEv. It only does the bookkeeping that every EVM
# metric relies on: turning a {date => daily value} hash into a running
# cumulative total, and adding a value weighted by a done ratio.
class BaseCalculateEvmTest < ActiveSupport::TestCase
  def setup
    @base = BaseCalculateEvm.new(Date.new(2026, 1, 10))
  end

  def test_basis_date_is_exposed
    assert_equal Date.new(2026, 1, 10), @base.basis_date
  end

  def test_create_cumulative_evm_sums_in_date_order_regardless_of_hash_order
    daily = { Date.new(2026, 1, 3) => 2.0, Date.new(2026, 1, 1) => 1.0, Date.new(2026, 1, 2) => 3.0 }

    cumulative = @base.send(:create_cumulative_evm, daily)

    assert_equal [Date.new(2026, 1, 1), Date.new(2026, 1, 2), Date.new(2026, 1, 3)], cumulative.keys
    assert_equal 1.0, cumulative[Date.new(2026, 1, 1)]
    assert_equal 4.0, cumulative[Date.new(2026, 1, 2)]
    assert_equal 6.0, cumulative[Date.new(2026, 1, 3)]
  end

  def test_add_daily_evm_value_starts_from_nil_and_accumulates_with_a_done_ratio
    value = @base.send(:add_daily_evm_value, nil, 10.0, 50)
    assert_equal 5.0, value

    value = @base.send(:add_daily_evm_value, value, 10.0, 100)
    assert_equal 15.0, value
  end

  def test_add_daily_evm_value_defaults_done_ratio_to_100
    assert_equal 8.0, @base.send(:add_daily_evm_value, nil, 8.0)
  end

  def test_cumulative_at_returns_entries_up_to_and_including_the_target_date
    cumulative = @base.send(:create_cumulative_evm,
                            Date.new(2026, 1, 1) => 1.0,
                            Date.new(2026, 1, 2) => 2.0,
                            Date.new(2026, 1, 3) => 3.0)
    @base.instance_variable_set(:@cumulative, cumulative)

    result = @base.cumulative_at(Date.new(2026, 1, 2))

    assert_equal [Date.new(2026, 1, 1), Date.new(2026, 1, 2)], result.keys
  end
end
