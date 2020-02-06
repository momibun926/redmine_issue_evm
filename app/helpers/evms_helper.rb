# evms helper.
module EvmsHelper
  include CommonHelper

  # Get used baseline name
  #
  # @return [String] balseline name (subject)
  def used_baseline_name
    "#{l(:label_baseline)} : #{@evmbaseline.find(params[:evmbaseline_id]).subject}" unless params[:evmbaseline_id].nil?
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
end
