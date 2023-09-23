# View Listner
#
class EvmHookViewListner < Redmine::Hook::ViewListener
  include IssueDataFetcher
  include BaselineDataFetcher
  include CalculateEvmLogic

  # plugin's css use all pages
  render_on :view_layouts_base_html_head, inline: "<%= stylesheet_link_tag 'issue_evm', :plugin => :redmine_issue_evm %>"

  # View hooks
  # view_projects_show_left
  #
  # Display EVM on overview page
  def view_projects_show_left(context)
    evm_setting = Evmsetting.find_by(project_id: context[:project].id)
    if evm_setting.present?
      cfg_param = {}
      cfg_param[:basis_date] = User.current.time_to_date(Time.current)
      # baseline
      selectable_baseline = selectable_baseline_list(context[:project])
      if selectable_baseline.present?
        cfg_param[:baseline_id] = selectable_baseline.first.id
        baseline_subject = selectable_baseline.first.subject
      end
      baselines = project_baseline(cfg_param[:baseline_id])
      # working hours
      working_hours = evm_setting.basis_hours
      # issues of project include disendants
      issues = evm_issues(context[:project])
      # spent time of project include disendants
      actual_cost = evm_costs(context[:project])
      # calculate EVM
      project_evm = CalculateEvm.new(baselines,
                                     issues,
                                     actual_cost,
                                     cfg_param)
    else
      project_evm = nil
      working_hours = nil
      baseline_subject = nil
    end
    # rendar partial view
    context[:controller].send(:render_to_string,
                              partial: "hooks/view_projects_show_left",
                              locals: { evm: project_evm,
                                        working_hours: working_hours,
                                        baseline_subject: baseline_subject })
  end
end
