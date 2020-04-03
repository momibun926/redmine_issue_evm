# Utility for evm
#
#
module EvmUtil
  # check baseline variance
  # Variance of baseline and actual plan
  #
  # @param [CalculateEvm] project_evm evm object of project
  # @return [hash] project state
  def check_baseline_variance(project_evm)
    pv_actual = project_evm.pv_actual
    pv_baseline = project_evm.pv_baseline
    project_state = {}
    if pv_baseline.present?
      project_state[:bac] = check_bac_variance pv_actual.bac.round(2), pv_baseline.bac.round(2)
      project_state[:due_date] = check_due_date_variance pv_actual.due_date, pv_baseline.due_date
      project_state[:schedule] = check_pv_daily_variance pv_actual.daily, pv_baseline.daily
    end
    project_state
  end

  # check bac variance
  #
  # @param [numeric] bac_actual bac of pv actual
  # @param [numeric] bac_baseline bac of pv baseline
  # @return [hash] state of bac
  def check_bac_variance(bac_actual, bac_baseline)
    bac_actual == bac_baseline ? l(:no_changed) : l(:bac_cahnged)
  end

  # check due date variance
  #
  # @param [date] due_date_actual due date of pv actual
  # @param [date] due_date_baseline due date of pv baseline
  # @return [hash] state of due date
  def check_due_date_variance(due_date_actual, due_date_baseline)
    due_date_actual == due_date_baseline ? l(:no_changed) : l(:due_date_changed)
  end

  # check daily pv variance
  #
  # @param [hash] bac_actual daily pv of pv actual
  # @param [hash] bac_baseline daily pv of pv baseline
  # @return [hash] state of daily pv
  def check_pv_daily_variance(pv_actual, pv_baseline)
    pv_actual == pv_baseline ? l(:no_changed) : l(:schedule_changed)
  end
end
