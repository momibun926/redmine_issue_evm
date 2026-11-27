# Utility for evm
#
#
module EvmUtil
  # check baseline variance
  # Variance of baseline and actual plan
  #
  # @param [CalculateEvm] project_evm evm object of project
  # @return [Hash] states of project(difference at baseline) BAC, due date, and schedule.
  def check_baseline_variance(project_evm)
    pv_actual = project_evm.pv_actual
    pv_baseline = project_evm.pv_baseline
    return {} if pv_baseline.blank?

    {
      bac: check_bac_variance(pv_actual.bac.round(2), pv_baseline.bac.round(2)),
      due_date: check_due_date_variance(pv_actual.due_date, pv_baseline.due_date),
      schedule: check_pv_daily_variance(pv_actual.daily, pv_baseline.daily)
    }
  end

  # check bac variance
  #
  # @param [Numeric] bac_actual bac of pv actual
  # @param [Numeric] bac_baseline bac of pv baseline
  # @return [String] state of bac
  def check_bac_variance(bac_actual, bac_baseline)
    bac_actual == bac_baseline ? l(:no_changed) : l(:bac_changed)
  end

  # check due date variance
  #
  # @param [Date] due_date_actual due date of pv actual
  # @param [Date] due_date_baseline due date of pv baseline
  # @return [String] state of due date
  def check_due_date_variance(due_date_actual, due_date_baseline)
    due_date_actual == due_date_baseline ? l(:no_changed) : l(:due_date_changed)
  end

  # check daily pv variance
  #
  # @param [Hash] pv_actual daily pv of pv actual
  # @param [Hash] pv_baseline daily pv of pv baseline
  # @return [String] state of daily pv
  def check_pv_daily_variance(pv_actual, pv_baseline)
    pv_actual == pv_baseline ? l(:no_changed) : l(:schedule_changed)
  end

  # Working days between two dates.
  # When exclude_holiday is on, the non-working days of Redmine
  # (Administration > Settings > Issue tracking) and the public holidays of
  # the region (holidays gem) are left out; when no day is left, all the days
  # are working days.
  #
  # @param [Date] start_date start date of issue
  # @param [Date] end_date end date of issue
  # @param [Boolean] exclude_holiday leave out the non-working days and holidays?
  # @param [String] region region of the holidays
  # @return [Array] working days
  def working_days(start_date, end_date, exclude_holiday, region)
    issue_days = (start_date..end_date).to_a
    if exclude_holiday
      working_days = issue_days.reject { |e| evm_non_working_day?(e) || public_holiday?(e, region) }
      working_days.empty? ? issue_days : working_days
    else
      issue_days
    end
  end

  # Whether a date is one of the non-working days of the week set in Redmine.
  # Read the same way as Redmine::Utils::DateCalculation#non_working_week_days
  # (1 = Monday ... 7 = Sunday; all seven days set means none).
  #
  # @param [Date] date date
  # @return [Boolean] true if it is a non-working day
  def evm_non_working_day?(date)
    @evm_non_working_week_days ||= begin
      days = Setting.non_working_week_days
      days.is_a?(Array) && days.size < 7 ? days.map(&:to_i) : []
    end
    @evm_non_working_week_days.include?(date.cwday)
  end

  # Whether a date is a public holiday of the region (holidays gem). Each date
  # is looked up once for each object: the issues of a project share most of
  # their days.
  #
  # @param [Date] date date
  # @param [String] region region of the holidays
  # @return [Boolean] true if it is a holiday
  def public_holiday?(date, region)
    @holiday_cache ||= {}
    key = [date, region]
    @holiday_cache.fetch(key) do
      holidays = Holidays.on(date, region)
      @holiday_cache[key] = holidays.present?
    end
  end
end
