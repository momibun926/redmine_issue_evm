# Trackers EVM controller.
# This controller provide tracker evm view.
#
# 1. selectable list for tracker view
# 2. calculate EVM each selected trackers
#
class EvmtrackersController < BaseevmController
  # menu
  menu_item :issuevm
  # index for tracker EVM view.
  #
  # 1. set options of view request
  # 2. get selectable list
  # 3. calculate EVM
  #
  def index
    # View options
    @cfg_param[:basis_date] = params[:basis_date]
    @cfg_param[:selected_tracker_id] = params[:selected_tracker_id]
    # default params
    set_default_params_for_other_evm
    # selectable tracker
    @selectable_tracker = selectable_tracker_list @project
    # calculate EVM (tracker)
    create_evm_data if @cfg_param[:selected_tracker_id].present?
  end

  private

  # Create evm data
  #
  # 1. evm data
  # 2. chart data
  #
  def create_evm_data
    # search condition
    condition = { tracker_id: @cfg_param[:selected_tracker_id] }
    # issues of trackers
    tracker_issues = evm_issues @project, condition
    # spent time fo trackers
    tracker_actual_cost = evm_costs @project, condition
    # create evm data
    @tracker_evm = CalculateEvm.new nil,
                                    tracker_issues,
                                    tracker_actual_cost,
                                    @cfg_param
    # description
    @tracker_evm.description = Tracker.where(id: @cfg_param[:selected_tracker_id]).pluck(:name).join(" ")
    # create chart data
    @tracker_evm_chart = evm_chart_data @tracker_evm
  end
end
