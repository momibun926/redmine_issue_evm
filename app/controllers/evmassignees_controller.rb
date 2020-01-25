# Asignee controller.
# This controller provide assignee evm view.
#
# 1. selectable list for assignee view
# 2. calculate EVM each selected assignees
# 3. create chart data
#
class EvmassigneesController < BaseevmController
  # index for assignee EVM view.
  #
  # 1. set options of view request
  # 2. get selectable list
  # 3. calculate EVM
  # 4. chart data
  #
  def index
    # View options
    @cfg_param[:basis_date] = params[:basis_date]
    @cfg_param[:selected_assignee_id] = params[:selected_assignee_id]
    @cfg_param[:no_use_baseline] = "true"
    @cfg_param[:forecast] = "false"
    @cfg_param[:display_performance] = "false"
    @cfg_param[:display_incomplete] = "false"
    # selectable assignee
    @selectable_assignees = selectable_assignee_list @project
    # calculate EVM (assignee)
    @assignee_evm = {}
    @assignee_evm_chart = {}
    unless @cfg_param[:selected_assignee_id].nil?
      # create evm data
      create_evm_data
    end
  end

  private

  # Create evm data
  #
  # 1. evm data
  # 2. chart data
  #
  def create_evm_data
    @cfg_param[:selected_assignee_id].each do |id|
      condition = if id.blank?
                    { assigned_to_id: nil }
                  else
                    { assigned_to_id: id }
                  end
      # issues of assignee
      assignee_issue = evm_issues @project, condition
      # spent time of assignee
      assignee_actual_cost = evm_costs @project, condition
      # calculate EVM
      @assignee_evm[id] = CalculateEvm.new nil,
                                           assignee_issue,
                                           assignee_actual_cost,
                                           @cfg_param
      # description
      @assignee_evm[id].description = assignee_name(id)
      # create chart data
      @assignee_evm_chart[id] = evm_chart_data @assignee_evm[id]
    end
  end
end
