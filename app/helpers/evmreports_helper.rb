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
end
