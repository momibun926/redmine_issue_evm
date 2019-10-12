# evm controller
class EvmsController < BaseevmController
  # Before action (override)
  before_action :authorize
  #
  # View of EVM
  #
  def index
    if @emv_setting.present?
      # ##################################
      # view options
      # ##################################
      # Basis date of calculate
      @cfg_param[:basis_date] = default_basis_date
      # baseline
      @cfg_param[:no_use_baseline] = params[:no_use_baseline]
      @cfg_param[:baseline_id] = default_baseline_id
      @evmbaseline = find_evmbaselines
      # evm explanation
      @cfg_param[:display_explanation] = params[:display_explanation]

      # ##################################
      # EVM
      # ##################################
      # Project(all versions)
      baselines = project_baseline @project, @cfg_param[:baseline_id]
      issues = evm_issues @project
      actual_cost = evm_costs @project
      @no_data = issues.blank?
      # EVM of project
      @project_evm = CalculateEvm.new baselines,
                                      issues,
                                      actual_cost,
                                      @cfg_param
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
    #
    # default basis date
    #
    def default_basis_date
        params[:basis_date].nil? ? Time.zone.today : params[:basis_date].to_date
    end
    #
    # default baseline. latest baseline
    #
    def default_baseline_id
      if params[:evmbaseline_id].nil?
        @evmbaseline.blank? ? nil : @evmbaseline.first.id
      else
        params[:evmbaseline_id]
      end
    end
    #
    # use fo option area
    #
    def find_evmbaselines
      Evmbaseline.where(project_id: @project.id).
                  order(created_on: :DESC)
    end
end
