# Base controller.
# This controller provide common functions.
#
# 1. before actions
# 2. read common setting of this plugin
# 3. default parameter
#
class BaseevmController < ApplicationController
  include IssueDataFetcher
  include BaselineDataFetcher
  include CalculateEvmLogic
  include ChartDataMaker
  include EvmSettingParamBuilder

  # Before action
  before_action :find_project, :find_common_setting

  private

  # find common setting
  #
  def find_common_setting
    # check view setting
    @emv_setting = Evmsetting.find_by(project_id: @project.id)
    @cfg_param = {}
    return if @emv_setting.blank?

    @cfg_param = cfg_param_from_setting(@emv_setting)
  end

  # find project object
  #
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
