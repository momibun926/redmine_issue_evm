# evms helper.
module EvmsHelper
  include CommonHelper

  # Get used baseline name
  #
  # @param [baseline] baseline baseline
  # @param [numeric] baseline_id baseline id
  # @return [String] balseline name (subject)
  def used_baseline_name(baseline, baseline_id)
    "#{l(:label_baseline)} : #{baseline.find(baseline_id).subject}" if baseline_id.present?
  end

  # Get baseline difference color
  # Except No change is red
  #
  # @param [string] str difference string
  # @return [String] CSS class, except no change is red.
  def difference_color(str)
    value = if str != l(:no_changed)
              "difference-red"
            else
              ""
            end
    content_tag(:td, str, class: value)
  end

  # project status
  #
  # @param [Array] status status of EV and status of PV
  # @return [String] Project status
  def project_status(status)
    l(status).join(",")
  end
end
