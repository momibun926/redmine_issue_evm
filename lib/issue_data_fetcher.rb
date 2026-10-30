# Issue data fetcher
# This module is a function to collect ISSUE records necessary to calculate EVM
# It also collects a selectable list that is optionally specified
#
module IssueDataFetcher
  # The rest of the queries live in their own files (lib/issue_data_fetcher/).
  include SelectableLists
  include ProjectSummary
  include BaselineDiff

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
end
