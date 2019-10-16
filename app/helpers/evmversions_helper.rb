# evms helper
module EvmversionsHelper
  include CommonHelper
  # Get project and version name
  #
  # @param [numeric] ver_id fixed version id
  # @return [String] project name, version name
  def version_chart_name(ver_id)
    ver = Version.find(ver_id)
    pro = Project.find(ver.project_id)
    pro.name + " - " + ver.name
  end
  
end
