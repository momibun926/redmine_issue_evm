# View Listner
#
class EvmHookListner < Redmine::Hook::ViewListener
  include IssueDataFetcher
  include CalculateEvmLogic

  # Project view
  def view_projects_show_left(context)
    @project = Project.find(context[:project].id)
    @emv_setting = Evmsetting.find_by(project_id: @project.id)

    html = '<div class="issues box">'
    html << '<h3 class="icon icon-issue">EVM</h3>'

    if @emv_setting.present?
      cfg_param = {}
      cfg_param[:basis_date] = User.current.time_to_date(Time.current)
      cfg_param[:no_use_baseline] = nil
      cfg_param[:display_explanation] = nil
      cfg_param[:baseline_id] = nil
      cfg_param[:working_hours] = @emv_setting.basis_hours
      # issues of project include disendants
      issues = evm_issues(context[:project])
      # spent time of project include disendants
      actual_cost = evm_costs(context[:project])
      @no_data = issues.blank?
      # calculate EVM
      @project_evm = CalculateEvm.new(nil,
                                      issues,
                                      actual_cost,
                                      cfg_param)
      html << "<p>#{l(:indicator_table_header_date)} #{@project_evm.basis_date}</p>"
      html << "<table id='evm-indicator-value-table' border='1' bordercolor = '#bbb'>"
      html << "<tr>"
      html << "<th>BAC</th>"
      html << "<th>PV</th>"
      html << "<th>EV</th>"
      html << "<th>AC</th>"
      html << "<th>SV</th>"
      html << "<th>CV</th>"
      html << "<th>SPI</th>"
      html << "<th>CPI</th>"
      html << "</tr>"
      html << "<tr>"
      html << "<td>#{@project_evm.bac}</td>"
      html << "<td>#{@project_evm.today_pv}</td>"
      html << "<td>#{@project_evm.today_ev}</td>"
      html << "<td>#{@project_evm.today_ac}</td>"
      html << "<td>#{@project_evm.today_sv}</td>"
      html << "<td>#{@project_evm.today_cv}</td>"
      html << "<td>#{@project_evm.today_spi}</td>"
      html << "<td>#{@project_evm.today_cpi}</td>"
      html << "</tr>"
      html << "<tr>"
      html << "<td>#{@project_evm.bac(cfg_param[:working_hours])}</td>"
      html << "<td>#{@project_evm.today_pv(cfg_param[:working_hours])}</td>"
      html << "<td>#{@project_evm.today_ev(cfg_param[:working_hours])}</td>"
      html << "<td>#{@project_evm.today_ac(cfg_param[:working_hours])}</td>"
      html << "<td>#{@project_evm.today_sv(cfg_param[:working_hours])}</td>"
      html << "<td>#{@project_evm.today_cv(cfg_param[:working_hours])}</td>"
      html << "<td>#{@project_evm.today_spi(cfg_param[:working_hours])}</td>"
      html << "<td>#{@project_evm.today_cpi(cfg_param[:working_hours])}</td>"
      html << "</tr>"
      html << "</table>"
      html << "<p>#{l(:explanation_upper_row)} #{l(:explanation_lower_row)}</p>"
    else
      html << "<p class='nodata'>#{l(:label_no_evm_setting)}</p>"
    end
    html << "</div>"
  end
end
