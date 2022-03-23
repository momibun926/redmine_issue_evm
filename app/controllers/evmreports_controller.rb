# Evm Reports controller.
#
class EvmreportsController < BaseevmController
  # menu
  menu_item :issuevm
  # index for parent issue EVM view.
  #
  # 1. set options of view request
  # 2. get selectable list
  # 3. calculate EVM of each parent issues
  #
  def index
    @cfg_param[:bac] = params[:bac]
  end

  # Create of report
  #
  def new
    @evm_report = ProjectEvmreport.new
    @cfg_param[:bac] = params[:bac]

  end

  # View of report
  #
  def show
    @evm_report = ProjectEvmreport.find(params[:id])
  end

  # Edit view of report
  #
  def edit
    @evm_report = ProjectEvmreport.find(params[:id])
  end

  # Update report
  #
  def update
    evm_report = ProjectEvmreport.find(params[:id])
    evm_report.update(evm_baseline_params)
    if evm_report.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: :index
    else
      render :edit
    end
  end

  # Create report
  #
  def create
    evm_report = ProjectEvmreport.new(evm_baseline_params)
    evm_report.project_id = @project.id
    evm_report.report_text = ""
    evm_report.status_date = l(:label_current_baseline)
    evm_report.created_user_id = User.current.id
    evm_report.created_on = Time.now.utc
    # Save
    if evm_report.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to action: :index
    else
      render :new
    end
  end

  # Delete report
  #
  def destroy
    # destroy
    evm_report = ProjectEvmreport.find(params[:id])
    evm_report.destroy
    # Message
    flash[:notice] = l(:notice_successful_delete)
    redirect_to action: :index
  end
  private

  # Strong parameter
  #
  def evm_report_params
    params.require(:projectevmreport).permit(:report_text, :status_date)
  end
end
