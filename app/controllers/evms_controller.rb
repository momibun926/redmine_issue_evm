
require 'redmine'

include EvmLogic

class EvmsController < ApplicationController
  unloadable

  menu_item :issueevm

  # filter
  before_filter :find_project, :authorize

  def index
  	@iss = actual_pv(@project.id)
  	@chart_data = {}
    @chart_data['planned_value'] = convert_to_chart(actual_pv(@project.id))
  	@pi = @project.id
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
