
include EvmLogic

class EvmsController < ApplicationController
  unloadable

  menu_item :issueevm

  # filter
  before_filter :find_project, :authorize

  def index
    @evm = IssueEvm.new(@project, Time.now.to_date, params[:forecast], params[:calcetc])

    @forecast_is_enabled = params[:forecast]
    @calc_etc_method = params[:calcetc]
    @display_explanation_is_enabled = params[:display_explanation]
    #future
    @display_version_is_enabled = params[:display_version]
    @display_performance_is_enabled = params[:display_performance]

  end

  def show
  end
  

private
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end  
end
