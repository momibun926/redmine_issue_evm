# evms helper.
module EvmsHelper
  include CommonHelper

  # Get used baseline name
  #
  # @param [Evmbaseline] baseline baseline
  # @param [Numeric] baseline_id baseline id, blank when no baseline is used
  # @return [String] "Baseline name : subject of the baseline", or "none" in place of the subject
  def used_baseline_name(baseline, baseline_id)
    name = baseline_id.present? ? baseline.find(baseline_id).subject : l(:label_baseline_none)
    "#{l(:label_baseline)} : #{name}"
  end

  # Get baseline difference color
  # Except No change is red
  #
  # @param [String] str difference string
  # @return [String] CSS class, except no change is red.
  def difference_color(str)
    value = str == l(:no_changed) ? "" : "difference-red"
    tag.td(str, class: value)
  end

  # project status
  #
  # @param [Array] status status of EV and status of PV
  # @return [String] Project status
  def project_status(status)
    l(status).join(",")
  end
end
