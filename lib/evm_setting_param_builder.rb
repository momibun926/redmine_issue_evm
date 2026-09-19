# Builds the shared cfg_param hash (EVM calculation + display options) from
# an Evmsetting record.
#
# BaseevmController#find_common_setting (used by EvmsController and the four
# breakdown controllers) and EvmHookViewListner#view_projects_show_left (the
# project overview sidebar widget) used to each build this hash by hand, and
# the two copies had drifted apart -- see the current-state analysis doc,
# sections 2 and 10:
#
# 1. The hook's copy only ever set :basis_date and :baseline_id, never
#    :exclude_holiday, :region, :forecast, :working_hours or the ETC method.
#    :exclude_holiday and :region feed CalculatePv directly, so the sidebar
#    widget's PV (and anything derived from it, like SV) could silently
#    differ from the main EVM page's for any project using those settings.
# 2. BaseevmController stored the ETC method under :calcetc, but
#    CalculateEvm#initialize reads options[:etc_method] -- a key-name
#    mismatch, so the ETC method setting (method1/method2/method3, see
#    Evmsetting#etc_method and CalculateEvm#etc_div_value) never actually
#    reached CalculateEvm from either call path; ETC/EAC/TCPI silently
#    behaved as method2 no matter what was selected in the EVM settings.
#
# Building the hash in one place, from the same Evmsetting record, keeps
# both callers in sync going forward instead of relying on two hand-written
# copies staying identical.
module EvmSettingParamBuilder
  # @param [Evmsetting] evm_setting the project's EVM plugin settings record
  # @return [Hash] cfg_param: the display options BaseevmController's views
  #   read (:display_performance, :display_incomplete, :limit_spi,
  #   :limit_cpi, :limit_cr) plus every option CalculateEvm#initialize
  #   accepts (:forecast, :etc_method, :working_hours, :exclude_holiday,
  #   :region). Callers still need to add their own request-specific keys
  #   (:basis_date, :baseline_id, ...) on top of this.
  def cfg_param_from_setting(evm_setting)
    {
      # plugin setting: chart
      display_performance: evm_setting.view_performance,
      display_incomplete: evm_setting.view_issuelist,
      # plugin setting: chart and EVM value table
      forecast: evm_setting.view_forecast,
      limit_spi: evm_setting.threshold_spi,
      limit_cpi: evm_setting.threshold_cpi,
      limit_cr: evm_setting.threshold_cr,
      # plugin setting: calculation evm
      etc_method: evm_setting.etc_method,
      working_hours: evm_setting.basis_hours,
      # plugin setting: holyday region
      exclude_holiday: evm_setting.exclude_holidays,
      region: evm_setting.region
    }
  end
end
