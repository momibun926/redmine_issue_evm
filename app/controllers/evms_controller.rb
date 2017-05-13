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
    # plugin setting
    @working_hours = default_setting('working_hours_of_day', 7.5).to_f
    @limit_spi = default_setting('limit_spi', 0.9).to_f
    @limit_cpi = default_setting('limit_cpi', 0.9).to_f
    @limit_cr = default_setting('limit_cr', 0.8).to_f
    @region = default_setting('holiday_region',:jp)
    # Basis date of calculate
    @basis_date = default_basis_date
    # baseline combo
    @evmbaseline = find_evmbaselines
    # option parameters
    @baseline_id = default_baseline_id
    @no_use_baseline = default_no_use_baseline
    @calcetc = default_calcetc
    @forecast = params[:forecast]
    @display_explanation = params[:display_explanation]
    @display_version = params[:display_version]
    @display_performance = params[:display_performance]
    @display_incomplete = params[:display_incomplete]
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
  end

  private

  # default basis date
  def default_basis_date
    params[:basis_date].nil? ? Date.today : params[:basis_date].to_date
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

  # view option.
  # Method of calculation
  def default_calcetc
    params[:calcetc].nil? ? 'method2' : params[:calcetc]
  end

  def default_setting(setting_name, defaultvalue)
    Setting.plugin_redmine_issue_evm[setting_name].blank? ? defaultvalue : Setting.plugin_redmine_issue_evm[setting_name]
  end

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_evmbaselines
    Evmbaseline.where('project_id = ? ', @project.id).order('created_on DESC')
  end
end
