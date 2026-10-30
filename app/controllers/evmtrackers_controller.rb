# Trackers EVM controller.
# This controller provides the "EVM broken down by tracker" view.
# See EvmBreakdownController for the shared index/create_evm_data logic.
#
class EvmtrackersController < EvmBreakdownController
  menu_item :issuevm

  private

  def breakdown_param
    :selected_tracker_id
  end

  def selectable_options
    selectable_tracker_list(@project)
  end

  def evm_inputs_for(id)
    condition = { tracker_id: id }
    description = Tracker.where(id: id).pluck(:name).join(" ")
    [evm_issues(@project, condition), evm_costs(@project, condition), description]
  end
end
