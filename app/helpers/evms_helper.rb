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
end
