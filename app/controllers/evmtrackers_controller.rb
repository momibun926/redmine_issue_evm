# Trackers EVM controller.
# This controller provide tracker evm view.
#
# 1. selectable list for tracker view
# 2. calculate EVM each selected trackers
#
class EvmtrackersController < BaseevmController
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
    @cfg_param[:no_use_baseline] = "true"
    @cfg_param[:forecast] = "false"
    @cfg_param[:display_performance] = "false"
    @cfg_param[:display_incomplete] = "false"
    # selectable tracker
    @selectable_tracker = selectable_tracker_list @project
    condition = { tracker_id: params[:selected_tracker_id] }
    # issues of trackers
    tracker_issues = evm_issues @project, condition
    # spent time fo trackers
    tracker_actual_cost = evm_costs @project, condition
    # calculate EVM
    unless tracker_issues.blank?
      # create evm data
      @tracker_evm = CalculateEvm.new nil,
                                      tracker_issues,
                                      tracker_actual_cost,
                                      @cfg_param
      # description
      @tracker_evm.description = Tracker.where(id: params[:selected_tracker_id]).pluck(:name).join(" ")
      # create chart data
      @tracker_evm_chart = evm_chart_data @tracker_evm
    end
  end
end
