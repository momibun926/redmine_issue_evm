# View Listner
#
class EvmHookViewListner < Redmine::Hook::ViewListener
  include IssueDataFetcher
  include ProjectEvmBuilder
  include EvmSettingParamBuilder
  # BaselineDataFetcher and CalculateEvmLogic are not included here -- see
  # BaseevmController for why (the same reasoning applies to this class).

  # plugin's css use all pages
  render_on :view_layouts_base_html_head,
            inline: "<%= stylesheet_link_tag 'issue_evm', :plugin => :redmine_issue_evm %>"

  # View hooks
  # view_projects_show_left
  #
  # Display EVM on overview page
  def view_projects_show_left(context)
    evm_setting = Evmsetting.find_by(project_id: context[:project].id)
    locals = evm_setting.present? ? overview_locals(context[:project], evm_setting) : {}
    # rendar partial view
    context[:controller].send(:render_to_string,
                              partial: "hooks/view_projects_show_left",
                              locals: { evm: locals[:evm],
                                        working_hours: locals[:working_hours],
                                        baseline_subject: locals[:baseline_subject] })
  end

  private

  # Locals of the overview partial, when the project has the EVM setting.
  #
  # @param [Project] project target project
  # @param [Evmsetting] evm_setting the project's EVM plugin settings record
  # @return [Hash] evm, working_hours and baseline_subject
  def overview_locals(project, evm_setting)
    # same shape as BaseevmController#find_common_setting, so the numbers
    # this widget shows can't silently drift from the main EVM page's
    # (see EvmSettingParamBuilder)
    cfg_param = cfg_param_from_setting(evm_setting)
    cfg_param[:basis_date] = User.current.time_to_date(Time.current)
    # baseline
    baseline = BaselineDataFetcher.selectable_baseline_list(project).presence&.first
    cfg_param[:baseline_id] = baseline.id if baseline
    # calculate EVM (shared with EvmsController, see ProjectEvmBuilder)
    { evm: build_project_evm(project, cfg_param),
      working_hours: evm_setting.basis_hours,
      baseline_subject: baseline&.subject }
  end
end
