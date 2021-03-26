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
    baseline_issue = create_baseline_issue_data baselines
    # new issue ids
    @new_issue_ids = new_issue_ids actual_issue, baseline_issue
    # remove issue ids
    @remove_issue_ids = remove_issue_ids actual_issue, baseline_issue
    # modify issue ids
    @rmodify_issue_ids = modify_issue_ids actual_issue, baseline_issue
    # get issue data
    @modify_issues = Issue.find(@rmodify_issue_ids)
    @new_issues = Issue.find(@new_issue_ids)
    @remove_issues = Issue.find(@remove_issue_ids)
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

  # new issue ids
  #
  # @param [array] actual_issue issue detail.
  # @param [array] baseline_issue baseline detail.
  # @return [array] new issue ids.
  def new_issue_ids(actual_issue, baseline_issue)
    actual_issue.keys - baseline_issue.keys
  end

  # remove issue ids
  #
  # @param [hash] actual_issue issue detail.
  # @param [hash] baseline_issue baseline detail.
  # @return [array] remove issue ids.
  def remove_issue_ids(actual_issue, baseline_issue)
    baseline_issue.keys - actual_issue.keys
  end

  # modify issue ids
  #
  # @param [hash] actual_issue issue detail.
  # @param [hash] baseline_issue baseline detail.
  # @return [array] modify issue ids.
  def modify_issue_ids(actual_issue, baseline_issue)
    ids = []
    (actual_issue.keys & baseline_issue.keys).each do | id |
      ids << id unless actual_issue[id] == baseline_issue[id]
    end
    ids
  end
end