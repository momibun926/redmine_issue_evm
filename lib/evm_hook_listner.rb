# View Listner
#
class EvmHookListner < Redmine::Hook::ViewListener
  include IssueDataFetcher
  include BaselineDataFetcher
  include CalculateEvmLogic

  # hook on overview page
  def view_projects_show_left(context)
    html = '<div class="issues box">'
    html << '<h3 class="icon icon-issue">EVM</h3>'
    proj = Project.find(context[:project].id)
    evm_setting = Evmsetting.find_by(project_id: proj.id)
    if evm_setting.present?
      cfg_param = {}
      cfg_param[:basis_date] = User.current.time_to_date(Time.current)
      # baseline
      selectable_baseline = selectable_baseline_list(proj)
      if selectable_baseline.present?
        cfg_param[:baseline_id] = selectable_baseline.first.id
        baseline_subject = selectable_baseline.first.subject
      end
      baselines = project_baseline(cfg_param[:baseline_id])
      # working hours
      cfg_param[:working_hours] = evm_setting.basis_hours
      # issues of project include disendants
      issues = evm_issues(context[:project])
      # spent time of project include disendants
      actual_cost = evm_costs(context[:project])
      # calculate EVM
      project_evm = CalculateEvm.new(baselines,
                                     issues,
                                     actual_cost,
                                     cfg_param)
      html << "<p>#{l(:indicator_table_header_date)}:#{project_evm.basis_date}"
      html << "  #{l(:label_baseline)}:#{baseline_subject}</p>"
      html << create_evm_summary_table(project_evm, cfg_param[:working_hours])
      html << "<p>#{l(:explanation_upper_row)} #{l(:explanation_lower_row)}</p>"
    else
      html << "<p class='nodata'>#{l(:label_no_evm_setting)}</p>"
    end
    html << "</div>"
  end

  private

  # Create evm summary table layout
  #
  # @param [CalculateEvm] project_evm calculate evm object
  # @param [numeric] working_hours working hours in setting
  # return [String] html(table)
  def create_evm_summary_table(project_evm, working_hours)
    html = "<table id='evm-indicator-value-table' border='1' bordercolor = '#bbb'>"
    html << "<tr>"
    html << "<th>BAC</th>"
    html << "<th>PV</th>"
    html << "<th>EV</th>"
    html << "<th>AC</th>"
    html << "<th>SV</th>"
    html << "<th>CV</th>"
    html << "<th>SPI</th>"
    html << "<th>CPI</th>"
    html << "</tr><tr>"
    html << "<td>#{project_evm.bac}</td>"
    html << "<td>#{project_evm.today_pv}</td>"
    html << "<td>#{project_evm.today_ev}</td>"
    html << "<td>#{project_evm.today_ac}</td>"
    html << "<td>#{project_evm.today_sv}</td>"
    html << "<td>#{project_evm.today_cv}</td>"
    html << "<td>#{project_evm.today_spi}</td>"
    html << "<td>#{project_evm.today_cpi}</td>"
    html << "</tr><tr>"
    html << "<td>#{project_evm.bac(working_hours)}</td>"
    html << "<td>#{project_evm.today_pv(working_hours)}</td>"
    html << "<td>#{project_evm.today_ev(working_hours)}</td>"
    html << "<td>#{project_evm.today_ac(working_hours)}</td>"
    html << "<td>#{project_evm.today_sv(working_hours)}</td>"
    html << "<td>#{project_evm.today_cv(working_hours)}</td>"
    html << "<td>#{project_evm.today_spi(working_hours)}</td>"
    html << "<td>#{project_evm.today_cpi(working_hours)}</td>"
    html << "</tr>"
    html << "</table>"
  end
end
