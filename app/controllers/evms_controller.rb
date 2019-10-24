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
  # Before action (override)
  before_action :authorize

  # View of main page.
  # If the settings are not entry, go to the settings page.
  #
  # 1. set options of view request
  # 2. get selectable list(baseline)
  # 3. calculate EVM
  # 4. fetch incomplete issues
  # 5. export CSV
  #
  def index
    if @emv_setting.present?
      # Basis date of calculate
      @cfg_param[:basis_date] = default_basis_date
      # baseline
      @cfg_param[:no_use_baseline] = params[:no_use_baseline]
      @evmbaseline = selectable_baseline_list @project
      @cfg_param[:baseline_id] = default_baseline_id
      # evm explanation
      @cfg_param[:display_explanation] = params[:display_explanation]
      # baseline
      baselines = project_baseline @project, @cfg_param[:baseline_id]
      # issues of project include disendants
      issues = evm_issues @project
      # spent time of project include disendants
      actual_cost = evm_costs @project
      @no_data = issues.blank?
      # calculate EVM
      @project_evm = CalculateEvm.new baselines,
                                      issues,
                                      actual_cost,
                                      @cfg_param
      # create chart data
      @evm_chart_data = evm_chart_data @project_evm
      # create performance chart data
      @performance_chart_data = performance_chart_data @project_evm
      # incomplete issues
      if @cfg_param[:display_incomplete]
        @incomplete_issues = incomplete_project_issues @project, @cfg_param[:basis_date]
        @no_data_incomplete_issues = @incomplete_issues.blank?
      end
      # project metrics
      @project_metrics = project_metrics @project, @project_evm
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
  #
  def default_basis_date
    params[:basis_date].nil? ? Time.zone.today : params[:basis_date].to_date
  end
  
  # default baseline. latest baseline
  #
  def default_baseline_id
    if params[:evmbaseline_id].nil?
      @evmbaseline.blank? ? nil : @evmbaseline.first.id
    else
      params[:evmbaseline_id]
    end
  end
end
