include EvmLogic, ProjectAndVersionValue


class EvmsController < ApplicationController
  unloadable

  menu_item :issuevm
  before_filter :find_project, :authorize

  def index
    # Basis date of calculate
    @basis_date = default_basis_date
    # baseline combo
    @evmbaseline = find_evmbaselines
    # option parameters
    @baseline_id = default_baseline_id
    @no_use_baseline = default_no_use_baseline
    @calcetc = default_calcetc
    @forecast = params[:forecast]
    @display_explanation = params[:display_explanation]
    @display_version = params[:display_version]
    @display_performance = params[:display_performance]
    #Project. all versions
    baselines = project_baseline @project, @baseline_id
    @include_sub_projets = default_include_sub_projets
    if @include_sub_projets
      issues = include_sub_project_issues @project
      actual_cost = include_sub_project_costs @project
    else
      issues = project_issues @project
      actual_cost = project_costs @project
    end
    @project_evm = IssueEvm.new( baselines, issues, actual_cost, @basis_date, @forecast, @calcetc, @no_use_baseline )
    #versions
    unless @project.versions.nil?
      @version_evm = {}
      @project.versions.each do |version|
        version_issue = version_issues @project, version.id
        version_actual_cost = version_costs @project, version.id
        unless version_issue.blank?
          @version_evm[version.id] = IssueEvm.new( nil, version_issue, version_actual_cost, @basis_date, nil, nil, true )
        end
      end
    end
    @no_data = issues.blank?
  end


private


  def default_basis_date
    params[:basis_date].nil? ? Time.now.to_date : params[:basis_date].to_date
  end


  def default_baseline_id
    if params[:evmbaseline_id].nil?
      id = @evmbaseline.blank? ? nil : @evmbaseline.first.id
    else
      id = params[:evmbaseline_id]
    end
  end


  def default_no_use_baseline
    @evmbaseline.blank? ? 'ture' : params[:no_use_baseline]
  end


  def default_calcetc
    params[:calcetc].nil? ? 'method2' : params[:calcetc]
  end


  def default_include_sub_projets
    if @no_use_baseline
      default = params[:include_sub_projets]
    else
      default = @baseline_id.blank? ? params[:include_sub_projets] : Evmbaseline.find(@baseline_id).include_sub_projects || params[:include_sub_projets]
    end  
  end


  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end


  def find_evmbaselines
    Evmbaseline.where("project_id = ? ", @project.id).order("created_on DESC")
  end


end
