class EvmsController < ApplicationController
  unloadable

  menu_item :IssueEVM

  # filter
  before_filter :find_project, :authorize

  def index
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
