# evms helper.
module EvmsHelper
  include CommonHelper

  # Get project name
  # Add baseline subject when baseline exists
  #
  # @return [String] project name, baseline subject
  def project_chart_name
    chart_title = if @baseline_id.nil?
                    @project.name
                  else
                    @project.name + '- ' + @evmbaseline.find(@baseline_id).subject
                  end
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
