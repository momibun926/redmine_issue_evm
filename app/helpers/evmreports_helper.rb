# reports helper
module EvmreportsHelper
  include CommonHelper
  include EvmUtil
  # Get baseline name
  #
  # @param [object] baseline baseline object
  # @return [String] baseline subject
  def baseline_name(baseline)
    baseline.present? ? baseline.subject : ""
  end

  # EVM(Status date) Difference
  #
  # @param [object] evm projectevmreport
  # @param [object] evm_prev projectevmreport(previusly)
  # @return [String] Difference
  def evm_report_status_date_difference(status_date, prev_status_date, exclude_holiday, region)
    working_days(prev_status_date.to_date, status_date.to_date, exclude_holiday, region).size unless prev_status_date.nil?
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
