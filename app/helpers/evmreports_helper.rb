# reports helper
module EvmreportsHelper
  include CommonHelper

  # Get baseline name
  #
  # @param [object] baseline baseline object
  # @return [String] baseline subject
  def baseline_name(baseline)
    baseline.present? ? baseline.subject : ""
  end

  # EVM Difference
  #
  # @param [object] evm projectevmreport
  # @param [object] evm_prev projectevmreport(previusly)
  # @return [String] Difference
  def evm_report_difference(report_value, prev_report_value)
    prev_report_value.nil? ? "" : (report_value - prev_report_value).to_f.round(1)
  end
end
