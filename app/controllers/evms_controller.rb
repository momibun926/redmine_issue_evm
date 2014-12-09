
include EvmLogic


class EvmsController < ApplicationController
  unloadable

  menu_item :issueevm

  model_object Evmbaseline

  # filter
  before_filter :find_project, :authorize

  def index
    # parameters
    @actual_basis = params[:actual_basis]
    @forecast = params[:forecast]
    @etc_method = params[:calcetc]
    @explanation = params[:display_explanation]
    @version_chart = params[:display_version]

    #Project. all versions
    baselines = project_baseline @project, params[:evmbaseline_id]
    issues = project_issues @project
    costs = project_costs @project
    @project_evm = IssueEvm.new(baselines, issues, costs, Time.now.to_date, params[:forecast], params[:calcetc], params[:actual_basis])

    #versions
    @version_evm = {}
    unless @project.versions.nil?
      @project.versions.each do |version|
        issues = version_issues @project, version.id
        costs = version_costs @project, version.id
        @version_evm[version.id] = IssueEvm.new(nil, issues, costs, Time.now.to_date, nil, nil, true)
      end
    end 

    #future
    @display_performance_is_enabled = params[:display_performance]

  end

private
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
