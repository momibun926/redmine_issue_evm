# EVM controller.
# This controller provide main evm view.
#
# 1. before action (override)
# 2. selectable list for baseline
# 3. calculate EVM all projects include desendant
# 4. incomplete issues
# 5. export to CSV
#
class EvmsController < BaseevmController
  include EvmUtil
  include ProjectEvmBuilder
  # menu
  menu_item :issuevm
  # Before action (override)
  before_action :authorize

  # View of main page.
  # If the settings are not entry, go to the settings page.
  #
  # 1. set options of view request
  # 2. get selectable list(baseline)
  # 3. calculate EVM of project
  # 4. fetch incomplete issues
  # 5. export CSV
  #
  def index
    # redirect emv setting
    return redirect_to(new_project_evmsetting_path) if @emv_setting.blank?

    assign_view_options
    # calculate EVM (project)
    create_evm_data
    # create other information
    create_other_information
    # for create report
    create_report_param
    # export
    respond_to do |format|
      format.html
      format.csv { send_evm_csv }
    end
  end

  private

  # Set the options of the view request to the cfg_param,
  # and the selectable baseline (and the selected one).
  #
  def assign_view_options
    # Basis date of calculate
    @cfg_param[:basis_date] = default_basis_date
    # baseline
    @cfg_param[:no_use_baseline] = params[:no_use_baseline]
    # evm explanation
    @cfg_param[:display_explanation] = params[:display_explanation]
    # selectable baseline
    @selectable_baseline = BaselineDataFetcher.selectable_baseline_list(@project)
    @cfg_param[:baseline_id] = default_baseline_id
  end

  # Create the values handed to the report page (today's EVM values).
  #
  def create_report_param
    report_param = { status_date: @cfg_param[:basis_date], baseline_id: @cfg_param[:baseline_id] }
    @report_param = report_param.merge(today_evm_values).merge(working_hours: @cfg_param[:working_hours])
  end

  # BAC and today's EVM values.
  #
  # @return [Hash] bac, pv, ev, ac, sv and cv
  def today_evm_values
    { bac: @project_evm.bac,
      pv: @project_evm.today_pv,
      ev: @project_evm.today_ev,
      ac: @project_evm.today_ac,
      sv: @project_evm.today_sv,
      cv: @project_evm.today_cv }
  end

  # Send the EVM as a CSV file.
  #
  def send_evm_csv
    send_data @project_evm.to_csv,
              type: "text/csv; header=present",
              filename: "evm_#{@project.name}_#{Date.current}.csv"
  end

  # create EVN data
  #
  def create_evm_data
    # no data when the project has no eligible issues at all
    @no_data = evm_issues(@project).blank?
    # calculate EVM (shared with EvmHookViewListner, see ProjectEvmBuilder)
    @project_evm = build_project_evm(@project, @cfg_param)
    # create chart data
    @evm_chart_data = ChartDataMaker.evm_chart_data(@project_evm)
    # create performance chart data
    @performance_chart_data = ChartDataMaker.performance_chart_data(@project_evm)
  end

  # create other information data
  #
  def create_other_information
    # incomplete issues
    if @cfg_param[:display_incomplete]
      @incomplete_issues = incomplete_project_issues(@project, @cfg_param[:basis_date])
      @no_data_incomplete_issues = @incomplete_issues.blank?
    end
    # project metrics
    @project_metrics = project_metrics(@project, @project_evm)
    # count
    @count_version_list = count_version_list(@project)
    @count_assignee_list = count_assignee_list(@project)
    @count_tracker_list = count_tracker_list(@project)
    # baseline difference
    @baseline_variance = check_baseline_variance(@project_evm)
  end

  # set default basis date
  #
  def default_basis_date
    params[:basis_date].nil? ? User.current.time_to_date(Time.current) : params[:basis_date].to_date
  end

  # set default aseline id
  #
  def default_baseline_id
    if params[:evmbaseline_id].nil? && params[:no_use_baseline].nil?
      @selectable_baseline.blank? ? nil : @selectable_baseline.first.id
    else
      params[:evmbaseline_id]
    end
  end
end
