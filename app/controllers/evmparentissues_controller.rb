# Parent issues controller.
# This controller provide assignee evm view.
#
# 1. selectable list for assignee issue view
# 2. calculate EVM each selected assignees
#
class EvmparentissuesController < BaseevmController
  # menu
  menu_item :issuevm
  # index for parent issue EVM view.
  #
  # 1. set options of view request
  # 2. get selectable list
  # 3. calculate EVM
  #
  def index
    # View options
    @cfg_param[:basis_date] = params[:basis_date]
    @cfg_param[:selected_parent_issue_id] = params[:selected_parent_issue_id]
    # default params
    set_default_params_for_other_evm
    # selectable parent issue
    @selectable_parent_issue = selectable_parent_issues_list @project
    # calculate EVM (parent issue)
    @parent_issue_evm = {}
    @parent_issue_evm_chart = {}
    create_evm_data if @cfg_param[:selected_parent_issue_id].present?
  end

  private

  # Create evm data
  #
  # 1. evm data
  # 2. chart data
  #
  def create_evm_data
    @cfg_param[:selected_parent_issue_id].each do |issue_id|
      # issues of parent issue
      parent_issue = parent_issues issue_id
      # spent time of parent issue
      parent_issue_actual_cost = parent_issue_costs issue_id
      # create array of EVM
      @parent_issue_evm[issue_id] = CalculateEvm.new nil,
                                                     parent_issue,
                                                     parent_issue_actual_cost,
                                                     @cfg_param
      # description
      @parent_issue_evm[issue_id].description = Issue.find(issue_id).subject
      # create chart data
      @parent_issue_evm_chart[issue_id] = evm_chart_data @parent_issue_evm[issue_id]
    end
  end
end
