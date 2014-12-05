
include EvmLogic


class EvmsController < ApplicationController
  unloadable

  menu_item :issueevm

  model_object Evmbaseline

  # filter
  before_filter :find_project, :authorize

  def index
    if params[:evmbaseline_id].nil?
      baselines = Evmbaseline.where('project_id = ? ', @project.id).order('created_on DESC').first.evmbaselineIssues
    else
      baselines = Evmbaseline.where('id = ? ', params[:evmbaseline_id]).first.evmbaselineIssues
    end
    issues = @project.issues.where( "start_date IS NOT NULL AND due_date IS NOT NULL")
    actual_cost = @project.issues.select('MAX(spent_on) AS spent_on, SUM(hours) AS sum_hours').
                  joins(:time_entries).
                  group('spent_on').collect { |issue| [issue.spent_on, issue.sum_hours] }

    @evm = IssueEvm.new(baselines, issues, actual_cost, Time.now.to_date, params[:forecast], params[:calcetc])

    @forecast_is_enabled = params[:forecast]
    @calc_etc_method = params[:calcetc]
    @display_explanation_is_enabled = params[:display_explanation]
    #future
    @display_version_is_enabled = params[:display_version]
    @display_performance_is_enabled = params[:display_performance]

  end

private
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end  
end
