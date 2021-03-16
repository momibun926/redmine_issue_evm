# Baseline defference ditail controller.
# This controller provide baseline diffeerence detail view.
#
# 1. index
#
class EvmbaselinediffdetailsController < BaseevmController
  # menu
  menu_item :issuevm
  # display baseline difference detail
  #
  def index
    # baseline
    @cfg_param[:baseline_id] = params[:baseline_id]
    baselines = project_baseline(params[:baseline_id])
    # issues of project include disendants
    issues = evm_issues(@project)
    # issue detail
    actual_issue = actual_issue_some_info issues
    # baseline detail
    @baseline_issue = baseline_issue_some_info baselines
    # get issue data
    @modify_issues = diff_modify_issues(actual_issue, @baseline_issue)
    @new_issues = diff_new_issues(actual_issue, @baseline_issue)
    @remove_issues = diff_remove_issues(actual_issue, @baseline_issue)
  end

  private

  # create issue detail hash
  #
  # @param [Issue] issues issue data.
  # @return [Hash] issue info of actual issue.
  def actual_issue_some_info(issues)
    temp = {}
    issues.each do |issue|
      actual_issue = {}
      actual_issue[:start_date] = issue.start_date
      actual_issue[:due_date] = issue.due_date
      actual_issue[:estimated_hours] = issue.estimated_hours
      temp[issue.id] = actual_issue
    end
    temp
  end

  # create baseline detail hash
  #
  # @param [EvmbaselineIssue] baselines issue date of baseline.
  # @return [Hash] issue info of baseline.
  def baseline_issue_some_info(baselines)
    temp = {}
    baselines.each do |baseline|
      bl_detail = {}
      bl_detail[:start_date] = baseline.start_date
      bl_detail[:due_date] = baseline.due_date
      bl_detail[:estimated_hours] = baseline.estimated_hours
      temp[baseline.issue_id] = bl_detail
    end
    temp
  end
end
