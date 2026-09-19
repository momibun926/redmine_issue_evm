# Exclude EVM controller.
# This controller provide exclude evm view.
#
# 1. Exclude issue of calculation EVM
#
class EvmexcludesController < BaseevmController
  # menu
  menu_item :issuevm
  # Before action -- was missing, and init.rb had no permission entry for
  # this controller at all (see the current-state analysis doc, section
  # 13); now covered by view_evms, same as the main EVM page.
  before_action :authorize
  # index for exclude issues EVM view.
  #
  def index
    # View options
    @cfg_param[:basis_date] = params[:basis_date]
    # total amount
    total_issue_ids = total_issue_amount(@project)
    # target amount
    target_issue_ids = target_issue_amount(@project)
    # exclude amount
    exclude_issus_ids = total_issue_ids - target_issue_ids
    # exclude issues
    @exclude_issues = Issue.where(id: exclude_issus_ids)
  end
end
