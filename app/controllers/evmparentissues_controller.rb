# Parent issues controller.
# This controller provides the "EVM broken down by parent issue" view.
# See EvmBreakdownController for the shared index/create_evm_data logic.
#
class EvmparentissuesController < EvmBreakdownController
  menu_item :issuevm

  private

  def breakdown_param
    :selected_parent_issue_id
  end

  def selectable_options
    selectable_parent_issues_list(@project)
  end

  def evm_inputs_for(id)
    [parent_issues(id), parent_issue_costs(id), Issue.find(id).subject]
  end
end
