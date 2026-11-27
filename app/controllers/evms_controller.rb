# EVM controller.
# This controller provide main evm view.
#
# 1. before action (override)
# 2. selectable list for baseline
# 3. calculate EVM all projects include desendant
# 4. incomplete issues
# 5. export to CSV
# 6. REST API (index.json / index.xml): EVM values of the project
#
class EvmsController < BaseevmController
  include EvmUtil
  include ProjectEvmBuilder
  # Values of the baseline option of the REST API.
  # latest: the latest baseline of the project, none: no baseline (the current issues)
  API_BASELINE_OPTIONS = %w[latest none].freeze
  # menu
  menu_item :issuevm
  # REST API (authenticated with the API key, as Redmine's own API)
  accept_api_auth :index
  # Before action (override)
  before_action :authorize
  # The options of the REST API must be valid
  before_action :check_api_options, only: :index, if: :api_request?
  # A baseline that is not of this project is not found
  before_action :find_selected_baseline, only: :index, unless: :api_request?

  # View of main page.
  # If the settings are not entry, go to the settings page.
  #
  # 1. set options of view request
  # 2. get selectable list(baseline)
  # 3. calculate EVM of project
  # 4. fetch incomplete issues
  # 5. export CSV, or the EVM values (REST API)
  #
  def index
    # redirect emv setting
    return no_evm_setting if @emv_setting.blank?

    assign_view_options
    # calculate EVM (project)
    create_evm_data
    respond_to do |format|
      format.html { create_page_information }
      format.csv { send_evm_csv }
      format.api
    end
  end

  private

  # The project has no EVM setting: the setting page, or an error (REST API).
  #
  def no_evm_setting
    return render_api_errors(l(:error_api_no_evm_setting)) if api_request?

    redirect_to(new_project_evmsetting_path)
  end

  # Chart data, other information and the values for the report (the page only).
  #
  def create_page_information
    # create chart data
    @evm_chart_data = ChartDataMaker.evm_chart_data(@project_evm)
    # create performance chart data
    @performance_chart_data = ChartDataMaker.performance_chart_data(@project_evm)
    # create other information
    create_other_information
    # for create report
    create_report_param
  end

  # Check the options of the REST API: baseline and basis_date.
  #
  def check_api_options
    errors = []
    errors << l(:error_api_baseline_option) unless API_BASELINE_OPTIONS.include?(api_baseline_option)
    errors << l(:error_api_basis_date) if params[:basis_date].present? && requested_basis_date.nil?
    render_api_errors(errors) if errors.any?
  end

  # The baseline option of the REST API; latest when it is not given.
  #
  # @return [Object] option value
  def api_baseline_option
    params[:baseline].presence || "latest"
  end

  # Set the options of the view request to the cfg_param,
  # and the selectable baseline (and the selected one).
  #
  def assign_view_options
    # Basis date of calculate
    @cfg_param[:basis_date] = basis_date_or_today
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
    # calculate EVM (shared with EvmHookViewListener, see ProjectEvmBuilder)
    @project_evm = build_project_evm(@project, @cfg_param)
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

  # The baseline selected by the request must be one of the project.
  def find_selected_baseline
    return if params[:evmbaseline_id].blank?

    render_404 unless Evmbaseline.exists?(id: params[:evmbaseline_id], project_id: @project.id)
  end

  # set default aseline id
  # REST API: the latest baseline, or none (see API_BASELINE_OPTIONS).
  #
  def default_baseline_id
    return (api_baseline_option == "latest" ? @selectable_baseline.first&.id : nil) if api_request?

    if params[:evmbaseline_id].nil? && params[:no_use_baseline].nil?
      @selectable_baseline.blank? ? nil : @selectable_baseline.first.id
    else
      params[:evmbaseline_id]
    end
  end
end
