# Issue data fetcher
# This module is a function to collect ISSUE records necessary to calculate EVM
# It also collects a selectable list that is optionally specified
#
module IssueDataFetcher
  # Condition of the issues the EVM is calculated from: an issue that has
  # a start date, and a due date or, when it has none, a version that has
  # a due date.
  #
  # @param [Arel::Table, Arel::Nodes::TableAlias] table the table of the issues
  #   (an alias for the ancestors of an issue, see #ancestor_join)
  # @return [Arel::Nodes::Grouping] condition
  def evm_target_condition(table = Issue.arel_table)
    started = table[:start_date].not_eq(nil)
    dated = started.and(table[:due_date].not_eq(nil))
    version_dated = started.and(table[:due_date].eq(nil)).
                      and(table[:fixed_version_id].in(Version.where.not(effective_date: nil).select(:id).arel))
    dated.or(version_dated)
  end

  # The issues above an issue in the tree (itself and its parents), joined as "ancestors".
  #
  # @return [Arel::Nodes::TableAlias] table of the ancestors
  def ancestor_table
    Issue.arel_table.alias("ancestors")
  end

  # Join of the issues to the issues above them in the tree (themselves and
  # their parents), which are named "ancestors" in the query.
  #
  # @return [Array<Arel::Nodes::Join>] join
  def ancestor_join
    issues = Issue.arel_table
    ancestors = ancestor_table
    issues.join(ancestors).
      on(ancestors[:root_id].eq(issues[:root_id]).
           and(ancestors[:lft].lteq(issues[:lft])).
           and(ancestors[:rgt].gteq(issues[:rgt]))).
      join_sources
  end

  # Get issues of EVM for PV and EV.
  # Include descendants project. Rerequires inputted start date and due date.
  # for use calculate PV and EV.
  #
  # @param [object] proj project object
  # @param [Hash, nil] condition fieldname(symbol) conditon value, nil is no condition
  # @return [Issue] issue object
  def evm_issues(proj, condition = nil)
    Issue.cross_project_scope(proj, "descendants").
      where(evm_target_condition).
      where(condition)
  end

  # Get descendants parent issue
  #
  # @param [Numeric] issue_id selected issue
  # @return [Issue] descendants issues
  def parent_issues(issue_id)
    Issue.joins(ancestor_join).
      where(evm_target_condition).
      where(evm_target_condition(ancestor_table)).
      where(ancestors: { id: issue_id })
  end

  # Get spent time of project.
  # Include descendants project.require inputted start date and due date.
  #
  # @param [Project] proj project
  # @return [Hash] Two column,spent_on,sum of hours
  def evm_costs(proj, condition = nil)
    Issue.cross_project_scope(proj, "descendants").
      where(evm_target_condition).
      where(condition).
      joins(:time_entries).
      group(:spent_on).sum(:hours)
  end

  # Get spent time of parent issue
  #
  # @param [Numeric] issue_id selected issue
  # @return [Hash] Two column,spent_on,sum of hours
  def parent_issue_costs(issue_id)
    Issue.joins(ancestor_join).
      where(evm_target_condition).
      where(evm_target_condition(ancestor_table)).
      where(ancestors: { id: issue_id }).
      joins(:time_entries).
      group(:spent_on).sum(:hours)
  end

  # Get pair of project id and fixed version id.
  #
  # @param [Project] proj project object
  # @return [Array] project_id, fixed_version_id
  def project_varsion_id_pair(proj)
    Issue.cross_project_scope(proj, "descendants").
      where(evm_target_condition).
      where.not(fixed_version_id: nil).
      distinct.
      pluck(:project_id, :fixed_version_id)
  end

  # Get assinee ids in project.
  # sort by assignee id.
  #
  # @param [Project] proj project object
  # @return [Issue] assigned_to_id
  def assignee_ids(proj)
    Issue.cross_project_scope(proj, "descendants").
      where(evm_target_condition).
      distinct.
      pluck(:assigned_to_id)
  end

  # Selectable assinee list.
  # sort by assignee id.
  #
  # @param [Project] proj project object
  # @return [Hash] assigenee name, assigned_to_id
  def selectable_assignee_list(proj)
    ids = assignee_ids proj
    selectable_list = {}
    ids.each do |id|
      user_name = assignee_name id
      selectable_list[user_name] = id
    end
    selectable_list
  end

  # Selectable version list.
  #
  # @param [Project] proj project object
  # @return [Issue] fixed_version_id, versions.name
  def selectable_version_list(proj)
    Issue.cross_project_scope(proj, "descendants").
      select(:fixed_version_id, "versions.name").
      where(evm_target_condition).
      joins(:fixed_version).
      group(:fixed_version_id, "versions.name")
  end

  # Selectable tracker list
  #
  # @param [Project] proj project object
  # @return [Issue] tracker_id, name
  def selectable_tracker_list(proj)
    Issue.cross_project_scope(proj, "descendants").
      select(:tracker_id, "trackers.name").
      where(evm_target_condition).
      joins(:tracker).
      group(:tracker_id, "trackers.name")
  end

  # Selectable parent issue list
  #
  # @param [Project] proj project object
  # @return [Issue] parent issues
  def selectable_parent_issues_list(proj)
    Issue.where(project_id: proj.id).
      select(:id, :subject).
      where(parent_id: nil).
      where((Issue.arel_table[:rgt] - Issue.arel_table[:lft]).gt(1))
  end

  # Get imcomplete issuees on basis date.
  #
  # @param [Project] proj project id
  # @param [Date] basis_date basis date
  # @return [Issue] issue object
  def incomplete_project_issues(proj, basis_date)
    issues = Issue.arel_table
    Issue.cross_project_scope(proj, "descendants").
      where(evm_target_condition).
      where(issues[:due_date].lteq(basis_date).
              and(issues[:closed_on].eq(nil).or(issues[:closed_on].gt(basis_date.end_of_day)))).
      where.not(done_ratio: 100).
      order(due_date: :ASC)
  end

  # project metrics
  # collect basic information of project.
  #
  # @param [Project] proj project object
  # @param [calculateEVM] evm calculate EVN class instance
  # @return [Hash] project metrics
  def project_metrics(proj, evm)
    metrics = {}
    # amount of total issue ids
    metrics[:total_issue_ids] = total_issue_amount(proj).length
    # amount of target issue ids
    metrics[:target_issue_ids] = target_issue_amount(proj).length
    # plan start date
    metrics[:plan_start_date] = evm.pv.start_date
    # plan due date
    metrics[:plan_due_date] = evm.pv.due_date
    # actual start date
    metrics[:actual_start_date] = [evm.ac.min_date, evm.ev.min_date].min
    # project state
    metrics[:state] = evm.project_state
    # Rest days to due date
    metrics[:due_date_difference] = evm.pv.rest_days
    # return
    metrics
  end

  # amount of issue in project
  #
  # @return [Numeric] array id total issues
  def total_issue_amount(proj)
    Issue.cross_project_scope(proj, "descendants").pluck(:id)
  end

  # amount of issue in target
  #
  # @return [Numeric] array id of target issues
  def target_issue_amount(proj)
    Issue.cross_project_scope(proj, "descendants").where(evm_target_condition).pluck(:id)
  end

  # amount of issue in version
  #
  # @param [Project] proj project object
  # @return [Hash] amount of issues. each versions.
  def count_version_list(proj)
    Issue.cross_project_scope(proj, "descendants").
      where(evm_target_condition).
      joins(:fixed_version).
      group("versions.name").count
  end

  # amount of issue in assignee
  #
  # @param [Project] proj project object
  # @return [Hash] count of issues. each assignees (include noassign).
  def count_assignee_list(proj)
    issues = Issue.cross_project_scope(proj, "descendants").
               where(evm_target_condition).
               group(:assigned_to_id).count
    count_list = {}
    issues.each do |id, count|
      user_name = assignee_name id
      count_list[user_name] = count
    end
    count_list
  end

  # amount of issue in tracker
  #
  # @param [Project] proj project object
  # @return [Hash] count of issues. each trackers.
  def count_tracker_list(proj)
    Issue.cross_project_scope(proj, "descendants").
      where(evm_target_condition).
      joins(:tracker).
      group("trackers.name").count
  end

  # user name
  # include nil. When userid is nil, no assigned name.
  #
  # @param [Numeric] id assignee id or user group id
  # @return [String] assignee name or user group name
  def assignee_name(id)
    return l(:no_assignee) if id.blank?

    User.find_by(id: id) || Group.find_by(id: id)
  end

  # children of parent isuue
  #
  # @param [Issue] issue parent issue
  # @return [Issue] cildren issue
  def issue_child(issue)
    Issue.where(root_id: issue.root_id).
      where(Issue.arel_table[:lft].gt(issue.lft)).
      where(Issue.arel_table[:rgt].lt(issue.rgt)).
      order(closed_on: :DESC).first
  end

  # latest setted done ratio journal
  #
  # @param [Issue] issue issue record
  # @param [Date] basis_date basis date
  # @return [Journal] first of journals
  def issue_journal(issue, basis_date)
    Journal.where(journalized_id: issue.id, journal_details: { prop_key: "done_ratio" }).
      where("created_on <= ?", basis_date.end_of_day).
      includes(:details).
      order("journals.created_on")
  end

  # new issues with a difference from Baseline
  #
  # @param [Hash] actual_issue issue detail.
  # @param [Hash] baseline_issue baseline detail.
  # @return [Issue] new issue issues.
  def diff_new_issues(actual_issue, baseline_issue)
    ids = actual_issue.keys - baseline_issue.keys
    Issue.find(ids)
  end

  # remove issues with a difference from Baseline
  #
  # @param [Hash] actual_issue issue detail.
  # @param [Hash] baseline_issue baseline detail.
  # @return [Array<Issue>] remove issue issues. An issue that has been deleted
  #   from Redmine is not included, since there is nothing left to show.
  def diff_remove_issues(actual_issue, baseline_issue)
    ids = baseline_issue.keys - actual_issue.keys
    Issue.where(id: ids).index_by(&:id).values_at(*ids).compact
  end

  # modify issues with a difference from Baseline
  #
  # @param [Hash] actual_issue issue detail.
  # @param [Hash] baseline_issue baseline detail.
  # @return [Issue] modify issue issues.
  def diff_modify_issues(actual_issue, baseline_issue)
    ids = []
    (actual_issue.keys & baseline_issue.keys).each do |id|
      ids << id unless actual_issue[id] == baseline_issue[id]
    end
    Issue.find(ids)
  end
end
