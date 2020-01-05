# Exclude EVM controller.
# This controller provide exclude evm view.
#
# 1. Exclude issue of calculation EVM
#
class EvmexcludesController < BaseevmController
  # menu
  menu_item :issuevm
  # index for exclude issues EVM view.
  #
  # 1. exclude issue of calculate EVM
  #
  def index
    # View options
    @cfg_param[:basis_date] = params[:basis_date]
    # total amount
    total_issue_ids = total_issue_amount @project
    # target amount
    target_issue_ids = target_issue_amount @project
    # exclude amount
    exclude_issus_ids = total_issue_ids - target_issue_ids
    # exclude issues
    @exclude_issues = Issue.where(id: exclude_issus_ids)
  end
end
