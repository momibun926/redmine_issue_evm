include EvmLogic, ProjectAndVersionValue

# evmasignee controller
class EvmversionsController < ApplicationController
  # menu
  menu_item :issuevm
  # Before action
  before_action :find_project
  #
  # 
  #
  def index
    emv_setting = Evmsetting.find_by(project_id: @project.id)
    @cfg_param = {}
    @cfg_param[:basis_date] = params[:basis_date]
    @cfg_param[:selected_parent_issue_id] = params[:selected_parent_issue_id]

    @cfg_param[:working_hours] = emv_setting.basis_hours
    @cfg_param[:exclude_holiday] = emv_setting.exclude_holidays
    @cfg_param[:region] = emv_setting.region

    @cfg_param[:limit_spi] = emv_setting.threshold_spi
    @cfg_param[:limit_cpi] = emv_setting.threshold_cpi
    @cfg_param[:limit_cr] = emv_setting.threshold_cr

    # ##################################
    # EVM optional (assignee)
    # ##################################
    @version_evm = {}
    project_version_ids = project_varsion_id_pair @project
    unless project_version_ids.nil?
      project_version_ids.each do |proj_id, ver_id|
        proj = Project.find(proj_id)
        condition = {fixed_version_id: ver_id}
        # issues of version
        version_issues = evm_issues proj, condition
        # spent time of version
        version_actual_cost = evm_costs proj, condition
        # create array of EVM
        @version_evm[ver_id] = IssueEvm.new nil,
                                            version_issues,
                                            version_actual_cost,
                                            basis_date: @cfg_param[:basis_date] ,
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
    # find project object by params
    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
end
