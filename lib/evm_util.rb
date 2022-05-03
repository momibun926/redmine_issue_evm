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
    project_state = {}
    if pv_baseline.present?
      project_state[:bac] = check_bac_variance(pv_actual.bac.round(2), pv_baseline.bac.round(2))
      project_state[:due_date] = check_due_date_variance(pv_actual.due_date, pv_baseline.due_date)
      project_state[:schedule] = check_pv_daily_variance(pv_actual.daily, pv_baseline.daily)
    end
    project_state
  end

  # check bac variance
  #
  # @param [Numeric] bac_actual bac of pv actual
  # @param [Numeric] bac_baseline bac of pv baseline
  # @return [String] state of bac
  def check_bac_variance(bac_actual, bac_baseline)
    bac_actual == bac_baseline ? l(:no_changed) : l(:bac_cahnged)
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

  # working days.
  # exclude weekends and holiday or include weekends and holiday.
  #
  # @param [Date] start_date start date of issue
  # @param [Date] end_date end date of issue
  # @param [Boolean] exclude_holiday holiday is exclude?
  # @param [String] region region
  # @return [Array] working days
  def working_days(start_date, end_date, exclude_holiday, region)
    issue_days = (start_date..end_date).to_a
    if exclude_holiday
      working_days = issue_days.reject { |e| e.wday.zero? || e.wday == 6 || e.holiday?(region) }
      working_days.length.zero? ? issue_days : working_days
    else
      issue_days
    end
  end
end
