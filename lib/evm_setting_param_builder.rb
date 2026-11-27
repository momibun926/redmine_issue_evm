# Builds the shared cfg_param hash (EVM calculation + display options) from
# an Evmsetting record.
#
# Used by BaseevmController#find_common_setting (the EVM pages) and
# EvmHookViewListner#view_projects_show_left (the project overview), so that
# both pass the same options -- holidays, region, ETC method and so on -- to
# the calculation. The ETC method goes under :etc_method, the key
# CalculateEvm reads.
module EvmSettingParamBuilder
  # @param [Evmsetting] evm_setting the project's EVM plugin settings record
  # @return [Hash] cfg_param: the display options BaseevmController's views
  #   read (:display_performance, :display_incomplete, :limit_spi,
  #   :limit_cpi, :limit_cr) plus every option CalculateEvm#initialize
  #   accepts (:forecast, :etc_method, :working_hours, :exclude_holiday,
  #   :region). Callers still need to add their own request-specific keys
  #   (:basis_date, :baseline_id, ...) on top of this.
  def cfg_param_from_setting(evm_setting)
    chart_param_from_setting(evm_setting).merge(calculation_param_from_setting(evm_setting))
  end

  # @param [Evmsetting] evm_setting the project's EVM plugin settings record
  # @return [Hash] chart and EVM value table options
  def chart_param_from_setting(evm_setting)
    {
      # plugin setting: chart
      display_performance: evm_setting.view_performance,
      display_incomplete: evm_setting.view_issuelist,
      # plugin setting: chart and EVM value table
      forecast: evm_setting.view_forecast,
      limit_spi: evm_setting.threshold_spi,
      limit_cpi: evm_setting.threshold_cpi,
      limit_cr: evm_setting.threshold_cr
    }
  end

  # @param [Evmsetting] evm_setting the project's EVM plugin settings record
  # @return [Hash] options of EVM calculation
  def calculation_param_from_setting(evm_setting)
    {
      # plugin setting: calculation evm
      etc_method: evm_setting.etc_method,
      working_hours: evm_setting.basis_hours,
      # plugin setting: holyday region
      exclude_holiday: evm_setting.exclude_holidays,
      region: evm_setting.region
    }
  end
end
