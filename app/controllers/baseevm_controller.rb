class BaseevmController < ApplicationController
  include IssueDataFetcher
  include CalculateEvmLogic
  # menu
  menu_item :issuevm
  # Before action
  before_action :find_project ,:find_common_setting
 
  private
    # find common setting
    #
    def find_common_setting
      # check view setting
      @emv_setting = Evmsetting.find_by(project_id: @project.id)
      @cfg_param = {}
      unless @emv_setting.blank?
        # plugin setting chart
        @cfg_param[:forecast] = @emv_setting.view_forecast
        @cfg_param[:display_performance] = @emv_setting.view_performance
        @cfg_param[:display_incomplete] = @emv_setting.view_issuelist
        # plugin setting calculation evm
        @cfg_param[:calcetc] = @emv_setting.etc_method
        @cfg_param[:working_hours] = @emv_setting.basis_hours
        @cfg_param[:limit_spi] = @emv_setting.threshold_spi
        @cfg_param[:limit_cpi] = @emv_setting.threshold_cpi
        @cfg_param[:limit_cr] = @emv_setting.threshold_cr
        # plugin setting holyday region
        @cfg_param[:exclude_holiday] = @emv_setting.exclude_holidays
        @cfg_param[:region] = @emv_setting.region
      end    
    end
    # find project object
    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

end
