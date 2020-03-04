# evms helper.
module EvmsHelper
  include CommonHelper

  # Get used baseline name
  #
  # @return [String] balseline name (subject)
  def used_baseline_name
    "#{l(:label_baseline)} : #{@evmbaseline.find(@cfg_param[:baseline_id]).subject}" unless @cfg_param[:baseline_id].nil?
  end

  # Get baseline difference color
  # Except No change is red
  #
  # @param [string] str difference string
  # @return [String] CSS class, except no change is red.
  def difference_color(str)
    value = if str != l(:no_changed)
              "class='difference-red'"
            else
              ""
            end
    value.html_safe
  end

  # Get annotationlabel
  #
  # @param [date] finished_date project finished date
  # @return [String] label name, "Basis date" or "Finished date"
  def basis_date_label(finished_date)
    value = finished_date.nil? ? l(:label_basis_date) : l(:label_finished_date)
    value.html_safe
  end

  # project status
  #
  # @param [Array] status status of EV and status of PV
  # @return [String] Project status
  def project_status(status)
    value = l(status).join(",")
    value.html_safe
  end
end
