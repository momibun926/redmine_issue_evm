require File.expand_path("../../test_helper", __dir__)

# Unit tests for the DB- and view-independent methods of EvmreportsHelper
# (app/helpers/evmreports_helper.rb), used by the EVM report list/detail views.
class EvmreportsHelperTest < ActiveSupport::TestCase
  include EvmreportsHelper

  FakeBaseline = Struct.new(:subject)

  # ---- baseline_name -----------------------------------------------------

  def test_baseline_name_is_the_baselines_subject
    assert_equal "Release 1", baseline_name(FakeBaseline.new("Release 1"))
  end

  def test_baseline_name_is_blank_when_no_baseline_was_used
    assert_equal "", baseline_name(nil)
  end

  # ---- evm_report_status_date_difference ----------------------------------

  def test_status_date_difference_is_nil_for_the_first_report
    assert_nil evm_report_status_date_difference(Date.new(2026, 6, 19), nil, false, nil)
  end

  def test_status_date_difference_counts_both_end_days_when_holidays_are_included
    # Mon Jun 15 .. Fri Jun 19, 2026
    days = evm_report_status_date_difference(Date.new(2026, 6, 19), Date.new(2026, 6, 15), false, nil)

    assert_equal 5, days
  end

  def test_status_date_difference_skips_weekends_when_holidays_are_excluded
    # Mon Jun 15 .. Mon Jun 22, 2026: 8 calendar days, 6 working days
    days = evm_report_status_date_difference(Date.new(2026, 6, 22), Date.new(2026, 6, 15), true, :jp)

    assert_equal 6, days
  end

  def test_status_date_difference_accepts_date_like_values
    # the helper calls #to_date, so Time values (as stored on the report) work too
    status_date = Time.utc(2026, 6, 19, 10, 0, 0)
    prev_status_date = Time.utc(2026, 6, 15, 9, 0, 0)
    days = evm_report_status_date_difference(status_date, prev_status_date, false, nil)

    assert_equal 5, days
  end

  # ---- evm_report_difference ----------------------------------------------

  def test_report_difference_is_blank_for_the_first_report
    assert_equal "", evm_report_difference(4.0, nil)
  end

  def test_report_difference_is_current_minus_previous_rounded_to_one_place
    assert_equal 1.5, evm_report_difference(5.5, 4.0)
    assert_equal(-1.2, evm_report_difference(4.0, 5.23))
    assert_equal 0.0, evm_report_difference(4.0, 4.0)
  end
end
