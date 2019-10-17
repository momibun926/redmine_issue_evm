# Version controller.
# This controller provide version evm view.
#
# 1. selectable list for assignee view
# 2. calculate EVM each selected assignees
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
      @cfg_param[:selected_version_id].each do |ver_id|
        proj_id = Version.find(ver_id).project_id
        proj = Project.find(proj_id)
        condition = {fixed_version_id: ver_id}
        # issues of version
        version_issues = evm_issues proj, condition
        # spent time of version
        version_actual_cost = evm_costs proj, condition
        # calculate EVM
        @version_evm[ver_id] = CalculateEvm.new nil,
                                                version_issues,
                                                version_actual_cost,
                                                @cfg_param
        # create chart data
        @version_evm_chart[ver_id] = chart_data @version_evm[ver_id]
      end
    end
  end

end
