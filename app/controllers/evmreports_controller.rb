# Evm Reports controller.
#
class EvmreportsController < BaseevmController
  # menu
  menu_item :issuevm
  # Before action -- was missing (see the current-state analysis doc,
  # section 13); view_project_evmreports was declared in init.rb but never
  # actually enforced without this, and was itself missing :update.
  before_action :authorize
  # The report of the project in the URL: one of another project is not found
  before_action :find_report, only: %i[show edit update destroy]
  # index for evm report
  #
  def index
    @evm_report = ProjectEvmreport.list(@project.id)
  end

  # Create of report
  #
  def new
    @evm_report = ProjectEvmreport.new
    @evm_report.project_id = @project.id
    @evm_report.baseline_id = params[:baseline_id]
    @evm_report.status_date = params[:status_date]
    assign_evm_values_in_days(@evm_report)
    # previus report and baseline
    previus_report_and_baseline_data
    # Set previus report text
    @evm_report.report_text = @evm_report_prev.report_text
  end

  # View of report
  #
  def show
    # previus report and baseline
    previus_report_and_baseline_data
  end

  # Edit report
  #
  def edit
    # previus report and baseline
    previus_report_and_baseline_data
  end

  # Update report
  #
  def update
    @evm_report.update(evm_report_params)
    stamp_updater(@evm_report)
    if @evm_report.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: :index
    else
      previus_report_and_baseline_data
      render :edit
    end
  end

  # Create report
  #
  def create
    @evm_report = build_report
    # Save
    if @evm_report.save
      delete_same_date_reports(@evm_report)
      flash[:notice] = l(:notice_successful_create)
      redirect_to action: :index
    else
      previus_report_and_baseline_data
      render :new
    end
  end

  # Delete report
  #
  def destroy
    @evm_report.destroy
    # Message
    flash[:notice] = l(:notice_successful_delete)
    redirect_to action: :index
  end

  private

  # Find the report of the request in the project of the URL (not found when it belongs to
  # another project, as when there is no such report).
  #
  def find_report
    @evm_report = ProjectEvmreport.find_by(id: params[:id], project_id: @project.id)
    render_404 unless @evm_report
  end

  # EVM values of a report (attribute) and the request parameter holding it (hours)
  EVM_REPORT_VALUES = { evm_bac: :bac,
                        evm_pv: :pv,
                        evm_ev: :ev,
                        evm_ac: :ac,
                        evm_sv: :sv,
                        evm_cv: :cv }.freeze
  private_constant :EVM_REPORT_VALUES

  # Set the EVM values of the request (hours) to the report, in days of working hours.
  #
  # @param [ProjectEvmreport] evm_report new report
  def assign_evm_values_in_days(evm_report)
    EVM_REPORT_VALUES.each do |attribute, param|
      evm_report[attribute] = params[param].to_f.fdiv(params[:working_hours].to_f).round(1)
    end
  end

  # New report of the project of the URL (whatever project the form says), by the current user.
  # It is not saved.
  #
  # @return [ProjectEvmreport] new report
  def build_report
    evm_report = ProjectEvmreport.new(evm_report_params)
    evm_report.project_id = @project.id
    stamp_creator(evm_report)
    evm_report
  end

  # Record the current user and time as the updater of the report.
  #
  # @param [ProjectEvmreport] evm_report report
  def stamp_updater(evm_report)
    evm_report.update_user_id = User.current.id
    evm_report.updated_on = Time.now.utc
  end

  # Record the current user and time as the creator (and updater) of the report.
  #
  # @param [ProjectEvmreport] evm_report new report
  def stamp_creator(evm_report)
    evm_report.create_user_id = User.current.id
    evm_report.created_on = Time.now.utc
    stamp_updater(evm_report)
    evm_report.author_id = User.current.id
  end

  # Delete the previus reports of the same status date.
  #
  # @param [ProjectEvmreport] evm_report saved report
  def delete_same_date_reports(evm_report)
    same_date_reports = ProjectEvmreport.where(project_id: evm_report.project_id,
                                               status_date: evm_report.status_date)
    same_date_reports.where.not(id: evm_report.id).delete_all
  end

  # Strong parameter
  #
  def evm_report_params
    params.require(:project_evmreport).permit(:baseline_id, :report_text, :status_date, *EVM_REPORT_VALUES.keys)
  end

  # Get previus report and baseline
  #
  def previus_report_and_baseline_data
    @evmbaseline = Evmbaseline.where(id: @evm_report.baseline_id).first
    @evm_report_prev = ProjectEvmreport.list(@project.id).previus(@evm_report.status_date).first || ProjectEvmreport.new
  end
end
