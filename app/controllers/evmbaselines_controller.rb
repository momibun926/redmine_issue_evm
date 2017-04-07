include ProjectAndVersionValue

# baseline controller
class EvmbaselinesController < ApplicationController
  unloadable

  menu_item :issuevm
  before_action :find_project, :authorize

  # display baseline list
  #
  def index
    @evm_baselines = Evmbaseline.where('project_id = ? ', @project.id)
                     .order('created_on DESC')
  end

  # Create of baseline
  #
  def new
    @evm_baselines = Evmbaseline.new
    issues = project_issues @project
    @start_date = issues.minimum(:start_date)
    @due_date = issues.maximum(:due_date) || issues.maximum(:effective_date)
    @bac = issues.sum(:estimated_hours).to_f
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
    evm_baselines = Evmbaseline.find(params[:id])
    evm_baselines.update_attributes(params[:evmbaseline])
    if evm_baselines.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: :index
    else
      redirect_to action: :edit
    end
  end

  # Create baseline
  #
  def create
    evm_baselines = Evmbaseline.new(params[:evmbaseline])
    evm_baselines.project_id = @project.id
    evm_baselines.state = l(:label_current_baseline)
    evm_baselines.author_id = User.current.id
    evm_baselines.updated_on = Time.now.utc
    # issues
    issues = project_issues @project
    issues.each do |issue|
      issue.due_date ||= Version.find(issue.fixed_version_id).effective_date
      baseline_issues = EvmbaselineIssue.new(issue_id: issue.id,
                                             start_date: issue.start_date,
                                             due_date: issue.due_date,
                                             estimated_hours: issue.estimated_hours,
                                             leaf: issue.leaf?
                                            )
      evm_baselines.evmbaselineIssues << baseline_issues
    end
    # update status
    Evmbaseline.where(project_id: @project.id)
      .update_all(state: l(:label_old_baseline))
    # Save
    if evm_baselines.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to action: :index
    else
      redirect_to action: :new
    end
  end

  # Delete baseline
  #
  def destroy
    # destroy
    evm_baselines = Evmbaseline.find(params[:id])
    evm_baselines.destroy
    # update status
    Evmbaseline.where(project_id: @project.id)
      .update_all(state: l(:label_old_baseline))
    evm_baselines = Evmbaseline.order('created_on desc').limit(1).first
    if evm_baselines.present?
      evm_baselines.state = l(:label_current_baseline)
      evm_baselines.save
    end
    # Message
    flash[:notice] = l(:notice_successful_delete)
    redirect_to action: :index
  end

  private

  # find project object
  #
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
