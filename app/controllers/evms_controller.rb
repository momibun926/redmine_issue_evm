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
      @region = emv_setting.region
      # Basis date of calculate
      @basis_date = default_basis_date
      # option parameters
      @baseline_id = default_baseline_id
      @no_use_baseline = default_no_use_baseline
      @display_explanation = params[:display_explanation]
      # baseline combo
      @evmbaseline = find_evmbaselines
      # Project. all versions
      baselines = project_baseline @project, @baseline_id
      issues = project_issues @project
      actual_cost = project_costs @project
      # incomplete issues
      @incomplete_issues = incomplete_project_issues @project, @basis_date
      # EVM of project
      @project_evm = IssueEvm.new baselines,
                                  issues,
                                  actual_cost,
                                  basis_date: @basis_date,
                                  forecast: @forecast,
                                  etc_method: @calcetc,
                                  no_use_baseline: @no_use_baseline,
                                  working_hours: @working_hours,
                                  region: @region
      # EVM of versions
      @version_evm = {}
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
                                              region: @region
        end
      end
      # EVM of assignee
      @assignee_evm = {}
      # Get assignee id and name
      project_assignee_ids = project_assignee_id_pair @project
      unless project_assignee_ids.nil?
        project_assignee_ids.each do |proj_id, assignee_id|
          # issues of assignee
          assignee_issue = assignee_issues proj_id,
                                           assignee_id
          # spent time of assignee
          assignee_actual_cost = assignee_costs proj_id,
                                                assignee_id
          @assignee_evm[ver_id] = IssueEvm.new nil,
                                               assignee_issue,
                                               assignee_actual_cost,
                                               basis_date: @basis_date,
                                               forecast: nil,
                                               etc_method: nil,
                                               no_use_baseline: true,
                                               working_hours: @working_hours,
                                               region: @region
        end
      end
      @no_data = issues.blank?
      @no_data_incomplete_issues = @incomplete_issues.blank?
      # export
      respond_to do |format|
        format.html
        format.csv do
          send_data @project_evm.to_csv,
                    type: 'text/csv; header=present',
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
    @evmbaseline.blank? ? 'ture' : params[:no_use_baseline]
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
