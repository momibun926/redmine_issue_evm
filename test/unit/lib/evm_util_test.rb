require File.expand_path("evm_calculation_test_helper", __dir__)

# Unit tests for EvmUtil (lib/evm_util.rb): the working-day calculation shared
# by CalculatePv and the reports helper, and the baseline-variance checks used
# by the EVM views.
#
# The variance checks return Redmine i18n strings through l(...). The host
# class below supplies its own l that returns the key it was asked for, so
# these tests pin down *which* message each branch picks without depending on
# a locale file or on Redmine::I18n being mixed into the test case.
class EvmUtilTest < ActiveSupport::TestCase
  include EvmTestStubs

  # Host for the EvmUtil mixin. Not defined inside the test case: EvmUtil is
  # mixed into plain classes (CalculatePv, EvmreportsHelper) in the plugin too.
  class Host
    include EvmUtil

    def l(key, *)
      key.to_s
    end
  end

  # Stand-ins for CalculatePv: check_baseline_variance only reads
  # #bac, #due_date and #daily from pv_actual / pv_baseline.
  FakePv = Struct.new(:bac, :due_date, :daily)
  FakeProjectEvm = Struct.new(:pv_actual, :pv_baseline)

  def setup
    @util = Host.new
  end

  # ---- working_days ------------------------------------------------------

  def test_working_days_includes_every_day_when_holidays_are_not_excluded
    # Mon Jun 15 .. Sun Jun 21, 2026 -- weekend days are kept
    days = @util.working_days(Date.new(2026, 6, 15), Date.new(2026, 6, 21), false, nil)

    assert_equal 7, days.length
    assert_equal Date.new(2026, 6, 15), days.first
    assert_equal Date.new(2026, 6, 21), days.last
  end

  def test_working_days_is_inclusive_of_both_ends_for_a_single_day
    days = @util.working_days(Date.new(2026, 6, 17), Date.new(2026, 6, 17), false, nil)

    assert_equal [Date.new(2026, 6, 17)], days
  end

  def test_working_days_drops_saturdays_and_sundays_when_holidays_are_excluded
    # Mon Jun 15 .. Sun Jun 21, 2026. Nothing in June is a public holiday in :jp,
    # so only the weekend is removed.
    days = @util.working_days(Date.new(2026, 6, 15), Date.new(2026, 6, 21), true, :jp)

    weekdays = (15..19).map { |d| Date.new(2026, 6, d) }
    assert_equal weekdays, days
    assert(days.none? { |d| d.saturday? || d.sunday? })
  end

  def test_working_days_falls_back_to_all_days_when_the_range_has_no_working_day
    # Sat Jun 20 .. Sun Jun 21: excluding the weekend would leave nothing, so
    # the full range is returned instead (a zero-length range would make
    # CalculatePv divide the estimate by zero days).
    days = @util.working_days(Date.new(2026, 6, 20), Date.new(2026, 6, 21), true, :jp)

    assert_equal [Date.new(2026, 6, 20), Date.new(2026, 6, 21)], days
  end

  def test_working_days_excludes_public_holidays_of_the_given_region
    # Christmas Day 2026 is a Friday. Depends on the holidays gem knowing it
    # for :us, so skip (rather than fail) if that data is not available.
    skip "holidays gem has no :us Christmas Day" unless Holidays.on(Date.new(2026, 12, 25), :us).any?

    days = @util.working_days(Date.new(2026, 12, 23), Date.new(2026, 12, 28), true, :us)

    assert_not_includes days, Date.new(2026, 12, 25)
    assert_includes days, Date.new(2026, 12, 23)
    assert_includes days, Date.new(2026, 12, 28)
    assert(days.none? { |d| d.saturday? || d.sunday? })
  end

  # ---- individual variance checks ---------------------------------------

  def test_check_bac_variance
    assert_equal "no_changed", @util.check_bac_variance(10.0, 10.0)
    assert_equal "bac_changed", @util.check_bac_variance(10.0, 12.5)
  end

  def test_check_due_date_variance
    assert_equal "no_changed", @util.check_due_date_variance(Date.new(2026, 1, 5), Date.new(2026, 1, 5))
    assert_equal "due_date_changed", @util.check_due_date_variance(Date.new(2026, 1, 5), Date.new(2026, 1, 9))
  end

  def test_check_pv_daily_variance
    same = { Date.new(2026, 1, 1) => 2.0 }
    assert_equal "no_changed", @util.check_pv_daily_variance(same, { Date.new(2026, 1, 1) => 2.0 })
    assert_equal "schedule_changed", @util.check_pv_daily_variance(same, { Date.new(2026, 1, 1) => 3.0 })
  end

  # ---- check_baseline_variance ------------------------------------------

  def test_check_baseline_variance_is_empty_when_there_is_no_baseline
    actual = FakePv.new(10.0, Date.new(2026, 1, 5), { Date.new(2026, 1, 1) => 2.0 })

    assert_equal({}, @util.check_baseline_variance(FakeProjectEvm.new(actual, nil)))
  end

  def test_check_baseline_variance_reports_no_change_when_baseline_matches_actual
    daily = { Date.new(2026, 1, 1) => 2.0 }
    actual = FakePv.new(10.0, Date.new(2026, 1, 5), daily)
    baseline = FakePv.new(10.0, Date.new(2026, 1, 5), daily.dup)

    state = @util.check_baseline_variance(FakeProjectEvm.new(actual, baseline))

    assert_equal({ bac: "no_changed", due_date: "no_changed", schedule: "no_changed" }, state)
  end

  def test_check_baseline_variance_reports_each_difference_independently
    actual = FakePv.new(10.0, Date.new(2026, 1, 5), { Date.new(2026, 1, 1) => 2.0 })
    baseline = FakePv.new(20.0, Date.new(2026, 1, 5), { Date.new(2026, 1, 1) => 2.0 })

    state = @util.check_baseline_variance(FakeProjectEvm.new(actual, baseline))

    assert_equal "bac_changed", state[:bac]
    assert_equal "no_changed", state[:due_date]
    assert_equal "no_changed", state[:schedule]
  end

  def test_check_baseline_variance_rounds_bac_to_two_places_before_comparing
    # 10.004 and 10.001 both round to 10.0, so they are not reported as changed.
    actual = FakePv.new(10.004, Date.new(2026, 1, 5), {})
    baseline = FakePv.new(10.001, Date.new(2026, 1, 5), {})

    state = @util.check_baseline_variance(FakeProjectEvm.new(actual, baseline))

    assert_equal "no_changed", state[:bac]
  end

  def test_public_holiday_looks_up_each_date_and_region_once
    new_years_day = Date.new(2026, 1, 1)
    calls = 0
    looked_up = lambda do |_date, region|
      calls += 1
      region == "jp" ? [{ name: "元日" }] : []
    end

    results = stub_method(Holidays, :on, looked_up) do
      [@util.public_holiday?(new_years_day, "jp"), @util.public_holiday?(new_years_day, "jp"),
       @util.public_holiday?(new_years_day, "us")]
    end

    assert_equal [true, true, false], results
    assert_equal 2, calls
  end

  def test_public_holiday_reads_the_holidays_gem
    assert @util.public_holiday?(Date.new(2026, 1, 12), "jp") # Coming of Age Day
    assert_not @util.public_holiday?(Date.new(2026, 1, 13), "jp")
  end

  # ---- non-working days of Redmine ---------------------------------------

  def test_working_days_follow_the_non_working_days_of_redmine
    # Mon Jun 15 .. Sun Jun 21, 2026, with only Sunday as a non-working day
    days = with_settings(non_working_week_days: %w[7]) do
      @util.working_days(Date.new(2026, 6, 15), Date.new(2026, 6, 21), true, :jp)
    end

    assert_equal (15..20).map { |d| Date.new(2026, 6, d) }, days
  end

  def test_working_days_with_friday_and_saturday_as_non_working_days
    days = with_settings(non_working_week_days: %w[5 6]) do
      @util.working_days(Date.new(2026, 6, 15), Date.new(2026, 6, 21), true, :jp)
    end

    assert_equal [15, 16, 17, 18, 21].map { |d| Date.new(2026, 6, d) }, days
  end

  def test_all_seven_non_working_days_mean_none_as_in_redmine
    days = with_settings(non_working_week_days: %w[1 2 3 4 5 6 7]) do
      @util.working_days(Date.new(2026, 6, 15), Date.new(2026, 6, 21), true, :jp)
    end

    assert_equal 7, days.length
  end

  def test_non_working_days_are_not_left_out_when_holidays_are_not_excluded
    days = with_settings(non_working_week_days: %w[7]) do
      @util.working_days(Date.new(2026, 6, 15), Date.new(2026, 6, 21), false, :jp)
    end

    assert_equal 7, days.length
  end
end
