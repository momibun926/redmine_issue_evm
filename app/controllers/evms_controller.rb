
include EvmLogic, ProjectAndVersionValue


class EvmsController < ApplicationController
  unloadable

  menu_item :issueevm

  model_object Evmbaseline

  # filter
  before_filter :find_project, :authorize, :only => :index

  def index
  	# Basis date of calculate
  	@basis_date = Time.now.utc.to_date
  	@evmbaseline = Evmbaseline.where('project_id = ? ', @project.id).order('created_on DESC')
    # option parameters
  	@baseline_id = params[:evmbaseline_id].nil? ? nil : params[:evmbaseline_id]
    @actual_basis = params[:actual_basis]
    @forecast = params[:forecast]
    @calcetc = params[:calcetc].nil? ? 'method2' : params[:calcetc]
    @display_explanation = params[:display_explanation]
    @display_version = params[:display_version]
    @display_performance = params[:display_performance]
    #Project. all versions
    baselines = project_baseline @project, @baseline_id
    issues = project_issues @project
    actual_cost = project_costs @project
    @project_evm = IssueEvm.new(baselines, issues, actual_cost, @basis_date, @forecast, @calcetc, @actual_basis, @display_performance )
    #versions
    @version_evm = {}
    unless @project.versions.nil?
      @project.versions.each do |version|
        issues = version_issues @project, version.id
        actual_cost = version_costs @project, version.id
        @version_evm[version.id] = IssueEvm.new(nil, issues, actual_cost, @basis_date, nil, nil, true, nil)
      end
    end 

  end

private
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
