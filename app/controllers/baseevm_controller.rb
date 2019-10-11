class BaseevmController < ApplicationController
  # menu
  menu_item :issuevm
  # Before action
  before_action :find_project
 
  private
    # find project object by params
    #
    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

end
