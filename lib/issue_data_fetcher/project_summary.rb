module IssueDataFetcher
  # Summary of the project shown on the main page: incomplete issues, project metrics and counts of the issues.
  # Mixed into IssueDataFetcher: the methods use its query helpers (evm_target_condition and others).
  module ProjectSummary
    # Get imcomplete issuees on basis date.
    #
    # @param [Project] proj project id
    # @param [Date] basis_date basis date
    # @return [Issue] issue object
    def incomplete_project_issues(proj, basis_date)
      Issue.cross_project_scope(proj, "descendants").
        where(evm_target_condition).
        where(incomplete_condition(basis_date)).
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
      issue_amount_metrics(proj).merge(plan_metrics(evm))
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

    private

    # Condition of the issues that are due by the basis date and not closed by the end of the day.
    #
    # @param [Date] basis_date basis date
    # @return [Arel::Nodes::And] condition
    def incomplete_condition(basis_date)
      issues = Issue.arel_table
      issues[:due_date].lteq(basis_date).
        and(issues[:closed_on].eq(nil).or(issues[:closed_on].gt(basis_date.end_of_day)))
    end

    # Amount of the issues of the project.
    #
    # @param [Project] proj project object
    # @return [Hash] total_issue_ids and target_issue_ids
    def issue_amount_metrics(proj)
      {
        # amount of total issue ids
        total_issue_ids: total_issue_amount(proj).length,
        # amount of target issue ids
        target_issue_ids: target_issue_amount(proj).length
      }
    end

    # Plan, actual start date and state of the project.
    #
    # @param [calculateEVM] evm calculate EVN class instance
    # @return [Hash] plan start date, plan due date, actual start date, state and rest days to due date
    def plan_metrics(evm)
      {
        plan_start_date: evm.pv.start_date,
        plan_due_date: evm.pv.due_date,
        actual_start_date: [evm.ac.min_date, evm.ev.min_date].min,
        state: evm.project_state,
        # Rest days to due date
        due_date_difference: evm.pv.rest_days
      }
    end
  end
end
