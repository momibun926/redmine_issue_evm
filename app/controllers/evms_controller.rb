
require 'redmine'

include EvmLogic

class EvmsController < ApplicationController
  unloadable

  menu_item :issueevm

  # filter
  before_filter :find_project, :authorize

  def index
    @evm = IssueEvm.new(@project, Time.now.to_date)
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
