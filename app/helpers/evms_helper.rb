# evms helper.
module EvmsHelper
  include CommonHelper
  # Get project name
  #
  # @return [String] project name, baseline subject
  def project_chart_name
    name = if @baseline_id.nil?
      @project.name
    else
      @project.name + "- " + @evmbaseline.find(@baseline_id).subject
    end
  end
  
end
