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
    baselines = project_baseline params[:baseline_id]
    # issues of project include disendants
    issues = evm_issues @project
    # issue detail
    @issue_detail = create_issue_detail_data issues
    # baseline detail
    @baseline_detail = create_baseline_detail_data baselines
  end

  private

  # create issue detail hash
  #
  # @param [issue] actual issue data.
  # @return [hash] detail of actual issue.
  def create_issue_detail_data(issues)
    temp = {}
    issues.each do |issue|
      issue_detail = {}
      issue_detail[:start_date] = issue.start_date
      issue_detail[:due_date] = issue.due_date
      issue_detail[:estimated_hours] = issue.estimated_hours
      temp[issue.id] = issue_detail
    end
    temp
  end

  # create baseline detail hash
  #
  # @param [baseline_issue] baselines issue date of baseline.
  # @return [hash] detail of baseline.
  def create_baseline_detail_data(baselines)
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
  # @param [hash] issue_detail issue detail.
  # @param [hash] baseline_detail baseline detail.
  # @return [array] new issue ids.
  def new_issue_ids(issue_detail, baseline_detail)
  end

  # remove issue ids
  #
  # @param [hash] issue_detail issue detail.
  # @param [hash] baseline_detail baseline detail.
  # @return [array] remove issue ids.
  def remove_issue_ids(issue_detail, baseline_detail)
  end

  # modify issue ids
  #
  # @param [hash] issue_detail issue detail.
  # @param [hash] baseline_detail baseline detail.
  # @return [array] modify issue ids.
  def modify_issue_ids(issue_detail, baseline_detail)
  end

end