include EvmLogic, ProjectAndVersionValue

# evmasignee controller
class EvmversionsController < BaseevmController
  #
  # View of version
  #
  def index
    # Get settings
    emv_setting = Evmsetting.find_by(project_id: @project.id)
    @cfg_param = {}
    # Setting
    @cfg_param[:working_hours] = emv_setting.basis_hours
    @cfg_param[:exclude_holiday] = emv_setting.exclude_holidays
    @cfg_param[:region] = emv_setting.region
    @cfg_param[:limit_spi] = emv_setting.threshold_spi
    @cfg_param[:limit_cpi] = emv_setting.threshold_cpi
    @cfg_param[:limit_cr] = emv_setting.threshold_cr
    # View options
    @cfg_param[:basis_date] = params[:basis_date]
    @cfg_param[:selected_version_id] = params[:selected_version_id]
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
        @version_evm[ver_id] = IssueEvm.new nil,
                                            version_issues,
                                            version_actual_cost,
                                            basis_date: @cfg_param[:basis_date] ,
                                            forecast: nil,
                                            etc_method: nil,
                                            no_use_baseline: "True",
                                            working_hours: @cfg_param[:working_hours],
                                            exclude_holiday: @cfg_param[:exclude_holiday],
                                            region: @cfg_param[:region]
      end
    end
  end
end
