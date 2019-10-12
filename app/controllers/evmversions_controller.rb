# evmasignee controller
class EvmversionsController < BaseevmController
  #
  # View of version
  #
  def index
    # View options
    @cfg_param[:basis_date] = params[:basis_date]
    @cfg_param[:selected_version_id] = params[:selected_version_id]
    @cfg_param[:no_use_baseline] = "True"
    @cfg_param[:forecast] = "False"
    @cfg_param[:display_performance] = "False"
    @cfg_param[:display_incomplete] = "False"
    #selectable version
    @selectable_versions = selectable_version_list @project
    # EVM optional (assignee)
    @version_evm = {}
    unless @cfg_param[:selected_version_id].nil?
      @cfg_param[:selected_version_id].each do |ver_id|
        proj_id = Version.find(ver_id).project_id
        proj = Project.find(proj_id)
        condition = {fixed_version_id: ver_id}
        # issues of version
        version_issues = evm_issues proj, condition
        # spent time of version
        version_actual_cost = evm_costs proj, condition
        # create array of EVM
        @version_evm[ver_id] = CalculateEvm.new nil,
                                                version_issues,
                                                version_actual_cost,
                                                @cfg_param
      end
    end
  end
end
