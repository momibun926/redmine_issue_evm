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
