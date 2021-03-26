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
    baselines = project_baseline params[:baseline_id]
    # issues of project include disendants
    issues = evm_issues @project
    # issue detail
    actual_issue = create_actual_issue_data issues
    # baseline detail
    @baseline_issue = create_baseline_issue_data baselines
    # get issue data
    @modify_issues = diff_modify_issues actual_issue,
                                        @baseline_issue
    @new_issues = diff_new_issues actual_issue,
                                  @baseline_issue
    @remove_issues = diff_remove_issues actual_issue,
                                        @baseline_issue
  end

  private

  # create issue detail hash
  #
  # @param [issue] actual issue data.
  # @return [hash] detail of actual issue.
  def create_actual_issue_data(issues)
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
  # @param [baseline_issue] baselines issue date of baseline.
  # @return [hash] detail of baseline.
  def create_baseline_issue_data(baselines)
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

  # difference of new issues
  #
  # @param [array] actual_issue issue detail.
  # @param [array] baseline_issue baseline detail.
  # @return [issue] new issue issues.
  def diff_new_issues(actual_issue, baseline_issue)
    ids = actual_issue.keys - baseline_issue.keys
    Issue.find(ids)
  end

  # difference of remove issues
  #
  # @param [hash] actual_issue issue detail.
  # @param [hash] baseline_issue baseline detail.
  # @return [issue] remove issue issues.
  def diff_remove_issues(actual_issue, baseline_issue)
    ids = baseline_issue.keys - actual_issue.keys
    Issue.find(ids)
  end

  # difference of modify issues
  #
  # @param [hash] actual_issue issue detail.
  # @param [hash] baseline_issue baseline detail.
  # @return [issue] modify issue issues.
  def diff_modify_issues(actual_issue, baseline_issue)
    ids = []
    (actual_issue.keys & baseline_issue.keys).each do | id |
      ids << id unless actual_issue[id] == baseline_issue[id]
    end
    Issue.find(ids)
  end
end