include EvmLogic, ProjectAndVersionValue

# evmasignee controller
class EvmparentissuesController < BaseevmController
  #
  # View of parent issues of EVM
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
    @cfg_param[:selected_parent_issue_id] = params[:selected_parent_issue_id]
    #selectable parent issue
    @selectable_parent_issue = selectable_parent_issues_list
    # EVM optional (parent issue)
    @parent_issue_evm = {}
    unless @cfg_param[:selected_parent_issue_id].nil?
      @cfg_param[:selected_parent_issue_id].each do |issue_id|
        # issues of parent issue
        parent_issue = parent_issues issue_id
        # spent time of parent issue
        parent_issue_actual_cost = parent_issue_costs issue_id
        # create array of EVM
        @parent_issue_evm[issue_id] = IssueEvm.new nil,
                                             parent_issue,
                                             parent_issue_actual_cost,
                                             basis_date: @cfg_param[:basis_date],
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
