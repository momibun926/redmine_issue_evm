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

    # plugin setting: chart
    @cfg_param[:display_performance] = @emv_setting.view_performance
    @cfg_param[:display_incomplete] = @emv_setting.view_issuelist
    # plugin setting: chart and EVM value table
    @cfg_param[:forecast] = @emv_setting.view_forecast
    @cfg_param[:limit_spi] = @emv_setting.threshold_spi
    @cfg_param[:limit_cpi] = @emv_setting.threshold_cpi
    @cfg_param[:limit_cr] = @emv_setting.threshold_cr
    # plugin setting: calculation evm
    @cfg_param[:calcetc] = @emv_setting.etc_method
    @cfg_param[:working_hours] = @emv_setting.basis_hours
    # plugin setting: holyday region
    @cfg_param[:exclude_holiday] = @emv_setting.exclude_holidays
    @cfg_param[:region] = @emv_setting.region
  end

  # find project object
  #
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
