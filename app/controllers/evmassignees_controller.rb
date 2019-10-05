include EvmLogic, ProjectAndVersionValue

# evmasignee controller
class EvmassigneesController < ApplicationController

  # menu
  menu_item :issuevm

  # Before action
  before_action :find_project

  # View of EVM
  #
  def index
  end

  private
    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
end
