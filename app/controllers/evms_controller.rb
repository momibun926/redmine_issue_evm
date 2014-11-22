
require 'redmine'

include EvmLogic

class EvmsController < ApplicationController
  unloadable

  menu_item :issueevm

  # filter
  before_filter :find_project, :authorize

  def index
  	actual_pv = actual_issue_pv(@project.id)
  	ev = issue_ev(@project.id)
  	ac = issue_ac(@project.id)

  	today_pv_value_hours = today_pv(actual_pv, 1)
  	today_pv_value_days = today_pv(actual_pv, 8)

  	today_ev_value_hours = today_ev(ev, 1)
  	today_ev_value_days = today_ev(ev, 8)

  	today_ac_value_hours = today_ac(ac, 1)
  	today_ac_value_days = today_ac(ac, 8)

  	@chart_data = {}
    @chart_data['planned_value'] = convert_to_chart(actual_pv)
    @chart_data['earned_value'] = convert_to_chart(ev)
    @chart_data['actual_cost'] = convert_to_chart(ac)
    #Tody's value
  	@todays_value = {}
  	@todays_value['complete_ev_value'] = complete_ev(ev, actual_pv)

  	@todays_value['bac_value_hours'] = bac(actual_pv, 1)
  	@todays_value['bac_value_days'] = bac(actual_pv, 8)

  	@todays_value['todays_pv_value_hours'] = today_pv_value_hours
  	@todays_value['todays_pv_value_days'] = today_pv_value_days

  	@todays_value['todays_ev_value_hours'] = today_ev_value_hours
  	@todays_value['todays_ev_value_days'] = today_ev_value_days

  	@todays_value['todays_ac_value_hours'] = today_ac_value_hours
  	@todays_value['todays_ac_value_days'] = today_ac_value_days

  	@todays_value['todays_sv_value_hours'] = today_sv(today_ev_value_hours, today_pv_value_hours)
  	@todays_value['todays_sv_value_days'] = today_sv(today_ev_value_days, today_pv_value_days)

  	@todays_value['todays_cv_value_hours'] = today_cv(today_ev_value_hours, today_ac_value_hours)
  	@todays_value['todays_cv_value_days'] = today_cv(today_ev_value_days, today_ac_value_days)

  	@todays_value['todays_spi_value_hours'] = today_spi(today_ev_value_hours, today_pv_value_hours)
  	@todays_value['todays_spi_value_days'] = today_spi(today_ev_value_days, today_pv_value_days)

  	@todays_value['todays_cpi_value_hours'] = today_cpi(today_ev_value_hours, today_ac_value_hours)
  	@todays_value['todays_cpi_value_days'] = today_cpi(today_ev_value_days, today_ac_value_days)
  	
  	@todays_value['todays_cr_value_hours'] = today_cr(today_ev_value_hours, today_ac_value_hours, today_pv_value_hours)
  	@todays_value['todays_cr_value_days'] = today_cr(today_ev_value_days, today_ac_value_days, today_pv_value_days)
    
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
