include EvmLogic, ProjectAndVersionValue

# evm controller
class EvmsController < ApplicationController
  unloadable

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
      # ##################################
      # saved settings
      # ##################################
      # plugin setting chart
      @forecast = emv_setting.view_forecast
      @display_version = emv_setting.view_version
      @display_performance = emv_setting.view_performance
      @display_incomplete = emv_setting.view_issuelist
      # plugin setting calculation evm
      @calcetc = emv_setting.etc_method
      @working_hours = emv_setting.basis_hours
      @limit_spi = emv_setting.threshold_spi
      @limit_cpi = emv_setting.threshold_cpi
      @limit_cr = emv_setting.threshold_cr
      # plugin setting holyday region
      @exclude_holiday = emv_setting.exclude_holidays
      @region = emv_setting.region

      # ##################################
      # view options
      # ##################################
      # Basis date of calculate
      @basis_date = default_basis_date
      # baseline
      @baseline_id = default_baseline_id
      @no_use_baseline = default_no_use_baseline
      @evmbaseline = find_evmbaselines
      # evm explanation
      @display_explanation = params[:display_explanation]
      # assignee
      @display_evm_assignee = params[:display_evm_assignee]
      # tracker
      @selectable_tracker = @project.trackers
      @display_evm_tracker = params[:display_evm_tracker]

      # ##################################
      # EVM
      # ##################################
      # Project(all versions)
      baselines = project_baseline @project, @baseline_id
      issues = project_issues @project
      @no_data = issues.blank?
      actual_cost = project_costs @project
      # EVM of project
      @project_evm = IssueEvm.new baselines,
                                  issues,
                                  actual_cost,
                                  basis_date: @basis_date,
                                  forecast: @forecast,
                                  etc_method: @calcetc,
                                  no_use_baseline: @no_use_baseline,
                                  working_hours: @working_hours,
                                  exclude_holiday: @exclude_holiday,
                                  region: @region
      # ##################################
      # EVM optional (versions)
      # ##################################
      if @display_version
        project_version_ids = project_varsion_id_pair @project
        unless project_version_ids.nil?
          project_version_ids.each do |proj_id, ver_id|
            version_issue = version_issues proj_id,
                                           ver_id
            version_actual_cost = version_costs proj_id,
                                                ver_id
            @version_evm[ver_id] = IssueEvm.new nil,
                                                version_issue,
                                                version_actual_cost,
                                                basis_date: @basis_date,
                                                forecast: nil,
                                                etc_method: nil,
                                                no_use_baseline: true,
                                                working_hours: @working_hours,
                                                exclude_holiday: @exclude_holiday,
                                                region: @region
          end
        end
      end
      # ##################################
      # EVM optional (assignee)
      # ##################################
      if @display_evm_assignee
        @assignee_evm = {}
        # Get assignee id and name
        project_assignee_ids = project_assignee_id_pair @project
        unless project_assignee_ids.nil?
          project_assignee_ids.each do |issue|
            # issues of assignee
            assignee_issue = assignee_issues @project,
                                             issue.assigned_to_id
            # spent time of assignee
            assignee_actual_cost = assignee_costs @project,
                                                  issue.assigned_to_id
            @assignee_evm[issue.assigned_to_id] = IssueEvm.new nil,
                                                               assignee_issue,
                                                               assignee_actual_cost,
                                                               basis_date: @basis_date,
                                                               forecast: nil,
                                                               etc_method: nil,
                                                               no_use_baseline: @no_use_baseline,
                                                               working_hours: @working_hours,
                                                               exclude_holiday: @exclude_holiday,
                                                               region: @region
          end
        end
      end

      # ##################################
      # EVM optional (selected trackers)
      # ##################################
      if @display_evm_tracker
        @trackers_evm = {}
        tracker_issues = tracker_issues @project, params[:selected_tracker_id]
        tracker_actual_cost = tracker_costs @project, params[:selected_tracker_id]
        @tracker_evm = IssueEvm.new baselines,
                                    tracker_issues,
                                    tracker_actual_cost,
                                    basis_date: @basis_date,
                                    forecast: @forecast,
                                    etc_method: @calcetc,
                                    no_use_baseline: @no_use_baseline,
                                    working_hours: @working_hours,
                                    exclude_holiday: @exclude_holiday,
                                    region: @region
      end
      # ##################################
      # incomplete issues
      # ##################################
      if @display_incomplete
        @incomplete_issues = incomplete_project_issues @project, @basis_date
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

  def find_evmbaselines
      Evmbaseline.where(project_id: @project.id).order(created_on: :DESC)
  end
end
