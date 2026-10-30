# Assignee controller.
# This controller provides the "EVM broken down by assignee" view.
# See EvmBreakdownController for the shared index/create_evm_data logic.
#
class EvmassigneesController < EvmBreakdownController
  menu_item :issuevm

  private

  def breakdown_param
    :selected_assignee_id
  end

  def selectable_options
    selectable_assignee_list(@project)
  end

  def evm_inputs_for(id)
    # search condition ("" / nil selection means "no assignee")
    condition = id.blank? ? { assigned_to_id: nil } : { assigned_to_id: id }
    [evm_issues(@project, condition), evm_costs(@project, condition), assignee_name(id)]
  end
end
