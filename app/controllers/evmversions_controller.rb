# Version controller.
# This controller provide version evm view.
#
# 1. selectable list for version view
# 2. calculate EVM each selected version
#
class EvmversionsController < BaseevmController
  # index for version EVM view.
  #
  # 1. set options of view request
  # 2. get selectable list
  # 3. calculate EVM
  #
  def index
    # View options
    @cfg_param[:basis_date] = params[:basis_date]
    @cfg_param[:selected_version_id] = params[:selected_version_id]
    @cfg_param[:no_use_baseline] = "true"
    @cfg_param[:forecast] = "false"
    @cfg_param[:display_performance] = "false"
    @cfg_param[:display_incomplete] = "false"
    # selectable version
    @selectable_versions = selectable_version_list @project
    # calculate EVM (version)
    @version_evm = {}
    @version_evm_chart = {}
    unless @cfg_param[:selected_version_id].nil?
      # create evm data
      create_evm_data
    end
  end

  private

  # Create evm data
  #
  # 1. evm data
  # 2. chart data
  #
  def create_evm_data
    @cfg_param[:selected_version_id].each do |ver_id|
      ver = Version.find(ver_id)
      proj = Project.find(ver.project_id)
      condition = { fixed_version_id: ver_id }
      # issues of version
      version_issues = evm_issues proj, condition
      # spent time of version
      version_actual_cost = evm_costs proj, condition
      # calculate EVM
      @version_evm[ver_id] = CalculateEvm.new nil,
                                              version_issues,
                                              version_actual_cost,
                                              @cfg_param
      # description
      @version_evm[ver_id].description =  "#{proj.name} #{ver.name}"
      # create chart data
      @version_evm_chart[ver_id] = evm_chart_data @version_evm[ver_id]
    end
  end
end
