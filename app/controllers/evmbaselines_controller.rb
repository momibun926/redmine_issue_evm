# Baseline controller.
# This controller provide baseline view.
#
# 1. index, new, show, edit, update, create, destroy
#
class EvmbaselinesController < BaseevmController
  # menu
  menu_item :issuevm
  # Before action -- was missing (see the current-state analysis doc,
  # section 13); manage_evmbaselines/view_evmbaselines were declared in
  # init.rb but never actually enforced without this.
  before_action :authorize
  # display baseline list
  #
  def index
    @evm_baselines = Evmbaseline.where(project_id: @project.id).order(created_on: :DESC)
  end

  # Create of baseline
  #
  def new
    @evm_baselines = Evmbaseline.new
    @evm_baselines.based_on = Time.zone.today
    assign_new_form_values
  end

  # View of Baseline
  #
  def show
    @evm_baselines = Evmbaseline.find(params[:id])
  end

  # Edit view of Baseline
  #
  def edit
    @evm_baselines = Evmbaseline.find(params[:id])
  end

  # Update baselie
  #
  def update
    @evm_baselines = Evmbaseline.find(params[:id])
    @evm_baselines.update(evm_baseline_params)
    if @evm_baselines.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: :index
    else
      render :edit
    end
  end

  # Create baseline
  #
  def create
    @evm_baselines = build_baseline
    # Save, and the earlier baselines are old from now on
    if save_current_baseline(@evm_baselines)
      flash[:notice] = l(:notice_successful_create)
      redirect_to action: :index
    else
      assign_new_form_values
      render :new
    end
  end

  # Delete baseline
  #
  def destroy
    # destroy
    evm_baselines = Evmbaseline.find(params[:id])
    evm_baselines.destroy
    # update status
    mark_baselines_old
    promote_latest_baseline
    # Message
    flash[:notice] = l(:notice_successful_delete)
    redirect_to action: :index
  end

  private

  # Build a baseline of the current plan: the posted values, the current
  # user, and a copy of the start date, due date and estimated hours of each
  # issue of the project. It is not saved.
  #
  # @return [Evmbaseline] new baseline (state: current)
  def build_baseline
    evm_baselines = new_baseline
    evm_issues(@project).each do |issue|
      evm_baselines.evmbaselineIssues << baseline_issue_of(issue)
    end
    evm_baselines
  end

  # New baseline of the project, by the current user.
  #
  # @return [Evmbaseline] new baseline (state: current), without issues
  def new_baseline
    evm_baselines = Evmbaseline.new(evm_baseline_params)
    evm_baselines.project_id = @project.id
    evm_baselines.state = l(:label_current_baseline)
    evm_baselines.author_id = User.current.id
    evm_baselines.updated_on = Time.now.utc
    evm_baselines
  end

  # Copy of the plan of an issue.
  #
  # @param [Issue] issue target issue. When it has no due date, the due date of its version is used.
  # @return [EvmbaselineIssue] new baseline issue
  def baseline_issue_of(issue)
    issue.due_date ||= Version.find(issue.fixed_version_id).effective_date
    EvmbaselineIssue.new(issue_id: issue.id,
                         start_date: issue.start_date,
                         due_date: issue.due_date,
                         estimated_hours: issue.estimated_hours,
                         leaf: issue.leaf?)
  end

  # Dates and hours of the project's issues, shown in the form of a new baseline.
  def assign_new_form_values
    issues = evm_issues(@project)
    @start_date = issues.minimum(:start_date)
    @due_date = issues.maximum(:due_date) || issues.maximum(:effective_date)
    @bac = issues.sum(:estimated_hours).to_f
  end

  # Save the baseline as the current one; the other baselines of the project become old.
  # When it cannot be saved (e.g. no subject), the baselines are left as they were.
  #
  # @param [Evmbaseline] evm_baselines new baseline
  # @return [Boolean] true if it was saved
  def save_current_baseline(evm_baselines)
    Evmbaseline.transaction do
      saved = evm_baselines.save
      mark_baselines_old(except: evm_baselines) if saved
      saved
    end
  end

  # Mark the baselines of the project as old.
  #
  # @param [Evmbaseline] except baseline that is kept as it is
  def mark_baselines_old(except: nil)
    baselines = Evmbaseline.where(project_id: @project.id)
    baselines = baselines.where.not(id: except.id) if except
    baselines.update_all(state: l(:label_old_baseline))
  end

  # Mark the newest baseline of the project as current.
  def promote_latest_baseline
    evm_baselines = Evmbaseline.where(project_id: @project.id).order(created_on: :desc).limit(1).first
    return if evm_baselines.blank?

    evm_baselines.state = l(:label_current_baseline)
    evm_baselines.save
  end

  # Strong parameter
  #
  def evm_baseline_params
    params.require(:evmbaseline).permit(:subject, :description, :based_on)
  end
end
