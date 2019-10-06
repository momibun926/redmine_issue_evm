include EvmLogic, ProjectAndVersionValue

# evmasignee controller
class EvmassigneesController < ApplicationController
  # menu
  menu_item :issuevm
  # Before action
  before_action :find_project
  #
  # index
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
    @cfg_param[:selected_assinee_id] = params[:selected_assinee_id]
    # selectable assignee
    @selectable_assignees = selectable_assignee_list @project
    # ##################################
    # EVM optional (assignee)
    # ##################################
    @assignee_evm = {}
    unless @cfg_param[:selected_assinee_id].nil?
      @cfg_param[:selected_assinee_id].each do |id|
        condition = if id.blank? 
                      {assigned_to_id: nil}
                    else 
                      {assigned_to_id: id}
                    end
        # issues of assignee
        assignee_issue = evm_issues @project,
                                    condition
        # spent time of assignee
        assignee_actual_cost = evm_costs @project,
                                         condition
        @assignee_evm[id] = IssueEvm.new nil,
                                         assignee_issue,
                                         assignee_actual_cost,
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
  
  private
    #
    # find project object by params
    #
    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
end
