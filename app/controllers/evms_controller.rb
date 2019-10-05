include EvmLogic, ProjectAndVersionValue

# evm controller
class EvmsController < ApplicationController

  # menu
  menu_item :issuevm

  # Before action
  before_action :find_project, :authorize

  # View of EVM
  #
  def index
    # check view setting
    emv_setting = Evmsetting.find_by(project_id: @project.id)
    if emv_setting.present?
      @cfg_param = {}
      # ##################################
      # saved settings
      # ##################################
      # plugin setting chart
      @cfg_param[:forecast] = emv_setting.view_forecast
      @cfg_param[:display_version] = emv_setting.view_version
      @cfg_param[:display_performance] = emv_setting.view_performance
      @cfg_param[:display_incomplete] = emv_setting.view_issuelist
      # plugin setting calculation evm
      @cfg_param[:calcetc] = emv_setting.etc_method
      @cfg_param[:working_hours] = emv_setting.basis_hours
      @cfg_param[:limit_spi] = emv_setting.threshold_spi
      @cfg_param[:limit_cpi] = emv_setting.threshold_cpi
      @cfg_param[:limit_cr] = emv_setting.threshold_cr
      # plugin setting holyday region
      @cfg_param[:exclude_holiday] = emv_setting.exclude_holidays
      @cfg_param[:region] = emv_setting.region
      # ##################################
      # view options
      # ##################################
      # Basis date of calculate
      @cfg_param[:basis_date] = default_basis_date
      # baseline
      @cfg_param[:no_use_baseline] = default_no_use_baseline
      @cfg_param[:baseline_id] = default_baseline_id
      @evmbaseline = find_evmbaselines
      # evm explanation
      @cfg_param[:display_explanation] = params[:display_explanation]
      # assignee
      @cfg_param[:display_evm_assignee] = params[:display_evm_assignee]
      # tracker
      @cfg_param[:display_evm_tracker] = params[:display_evm_tracker]
      @selectable_tracker = @project.trackers
      # parent issue
      @cfg_param[:display_evm_parent_issue] = params[:display_evm_parent_issue]
      @selectable_parent_issue = find_parent_issues

      # ##################################
      # EVM
      # ##################################
      # Project(all versions)
      baselines = project_baseline @project, @cfg_param[:baseline_id]
      issues = evm_issues @project
      actual_cost = evm_costs @project
      @no_data = issues.blank?
      # EVM of project
      @project_evm = IssueEvm.new baselines,
                                  issues,
                                  actual_cost,
                                  basis_date: @cfg_param[:basis_date] ,
                                  forecast: @cfg_param[:forecast],
                                  etc_method: @cfg_param[:calcetc],
                                  no_use_baseline: @cfg_param[:no_use_baseline],
                                  working_hours: @cfg_param[:working_hours],
                                  exclude_holiday: @cfg_param[:exclude_holiday],
                                  region: @cfg_param[:region]
      # ##################################
      # EVM optional (versions)
      # ##################################
      if @cfg_param[:display_version]
        @version_evm = {}
        project_version_ids = project_varsion_id_pair @project
        unless project_version_ids.nil?
          project_version_ids.each do |proj_id, ver_id|
            proj = Project.find(proj_id)
            condition = {fixed_version_id: ver_id}
            # issues of version
            version_issues = evm_issues proj,
                                        condition
            # spent time of version
            version_actual_cost = evm_costs proj,
                                            condition
            @version_evm[ver_id] = IssueEvm.new nil,
                                                version_issues,
                                                version_actual_cost,
                                                basis_date: @cfg_param[:basis_date] ,
                                                forecast: nil,
                                                etc_method: nil,
                                                no_use_baseline: @cfg_param[:no_use_baseline],
                                                working_hours: @cfg_param[:working_hours],
                                                exclude_holiday: @cfg_param[:exclude_holiday],
                                                region: @cfg_param[:region]
          end
        end
      end
      # ##################################
      # EVM optional (assignee)
      # ##################################
      if @cfg_param[:display_evm_assignee]
        @assignee_evm = {}
        # Get assignee ids
        project_assignee_ids = project_assignee_id_pair @project
        unless project_assignee_ids.nil?
          project_assignee_ids.each do |issue|
            condition = {assigned_to_id: issue.assigned_to_id}
            # issues of assignee
            assignee_issue = evm_issues @project,
                                        condition
            # spent time of assignee
            assignee_actual_cost = evm_costs @project,
                                             condition
            @assignee_evm[issue.assigned_to_id] = IssueEvm.new nil,
                                                               assignee_issue,
                                                               assignee_actual_cost,
                                                               basis_date: @cfg_param[:basis_date],
                                                               forecast: nil,
                                                               etc_method: nil,
                                                               no_use_baseline: @cfg_param[:no_use_baseline],
                                                               working_hours: @cfg_param[:working_hours],
                                                               exclude_holiday: @cfg_param[:exclude_holiday],
                                                               region: @cfg_param[:region]
          end
        end
      end
      # ##################################
      # EVM optional (selected trackers)
      # ##################################
      if @cfg_param[:display_evm_tracker]
        condition = {tracker_id: params[:selected_tracker_id]}
        # issues of trackers
        tracker_issues = evm_issues @project,
                                    condition
        # spent time fo trackers
        tracker_actual_cost = evm_costs @project,
                                        condition
        @tracker_evm = IssueEvm.new baselines,
                                    tracker_issues,
                                    tracker_actual_cost,
                                    basis_date: @cfg_param[:basis_date],
                                    forecast: nil,
                                    etc_method: nil,
                                    no_use_baseline: @cfg_param[:no_use_baseline],
                                    working_hours: @cfg_param[:working_hours],
                                    exclude_holiday: @cfg_param[:exclude_holiday],
                                    region: @cfg_param[:region]
      end
      # ##################################
      # EVM optional (selected parent issue)
      # ##################################
      if @cfg_param[:display_evm_parent_issue]
        @parent_issue_evm = {}
        selected_prent_issue_ids = params[:selected_parent_issue_id]
        unless selected_prent_issue_ids.nil?
          selected_prent_issue_ids.each do |parent_issue_id|
            parent_issue = parent_issues parent_issue_id
            parent_issue_actual_cost = parent_issue_costs parent_issue_id
            @parent_issue_evm[parent_issue_id] = IssueEvm.new baselines,
                                                              parent_issue,
                                                              parent_issue_actual_cost,
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
      # ##################################
      # incomplete issues
      # ##################################
      if @cfg_param[:display_incomplete]
        @incomplete_issues = incomplete_project_issues @project, @cfg_param[:basis_date] 
        @no_data_incomplete_issues = @incomplete_issues.blank?
      end
      # ##################################
      # export
      # ##################################
      respond_to do |format|
        format.html
        format.csv do
          send_data @project_evm.to_csv,
                    type: "text/csv; header=present",
                    filename: "evm_#{@project.name}_#{Date.current}.csv"
        end
      end
    else
      # redirect emv setting
      redirect_to new_project_evmsetting_path
    end
  end

  private
    # default basis date
    def default_basis_date
        params[:basis_date].nil? ? Time.zone.today : params[:basis_date].to_date
    end
    # default baseline. latest baseline
    def default_baseline_id
      if params[:evmbaseline_id].nil?
        @evmbaseline.blank? ? nil : @evmbaseline.first.id
      else
        params[:evmbaseline_id]
      end
    end
    # view option.
    # use baseline
    def default_no_use_baseline
      @evmbaseline.blank? ? "ture" : params[:no_use_baseline]
    end

    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
    # use fo option area
    def find_evmbaselines
      Evmbaseline.where(project_id: @project.id).
                  order(created_on: :DESC)
    end
    # use fo option area
    def find_parent_issues
      Issue.where(project_id: @project.id).
            where(parent_id: nil).
            where("( rgt - lft ) > 1")
    end
end
