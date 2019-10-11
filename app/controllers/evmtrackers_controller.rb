include EvmLogic, ProjectAndVersionValue

# evmasignee controller
class EvmtrackersController < ApplicationController
  # menu
  menu_item :issuevm
  # Before action
  before_action :find_project
  #
  # 
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
    @cfg_param[:selected_tracker_id] = params[:selected_tracker_id]
    @selectable_tracker = @project.trackers
    # EVM optional (selected trackers)
    condition = {tracker_id: params[:selected_tracker_id]}
    # issues of trackers
    tracker_issues = evm_issues @project, condition
    # spent time fo trackers
    tracker_actual_cost = evm_costs @project, condition
    @tracker_evm = IssueEvm.new nil,
                                tracker_issues,
                                tracker_actual_cost,
                                basis_date: @cfg_param[:basis_date],
                                forecast: nil,
                                etc_method: nil,
                                no_use_baseline: "True",
                                working_hours: @cfg_param[:working_hours],
                                exclude_holiday: @cfg_param[:exclude_holiday],
                                region: @cfg_param[:region]
  end

  private
    # find project object by params
    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
end
