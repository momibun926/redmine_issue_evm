# Get data of Calculation EVM
#
module ProjectAndVersionValue
  # Calculation common condition of issue"s select
  SQL_COM = "(issues.start_date IS NOT NULL AND issues.due_date IS NOT NULL) " +
            " OR " +
            "(issues.start_date IS NOT NULL " +
            " AND " +
            " issues.due_date IS NULL " +
            " AND " +
            " issues.fixed_version_id IN (SELECT id FROM versions WHERE effective_date IS NOT NULL))"

  SQL_COM_ANC = "(ancestors.start_date IS NOT NULL AND ancestors.due_date IS NOT NULL) " +
	            " OR " +
	            "(ancestors.start_date IS NOT NULL " +
	            " AND " +
	            " ancestors.due_date IS NULL " +
	            " AND " +
	            " ancestors.fixed_version_id IN (SELECT id FROM versions WHERE effective_date IS NOT NULL))"

  # Get Issues of Baseline.(start date, due date, estimated hours)
  # When baseline_id is nil,latest baseline of project.
  #
  # @param [numeric] project_id project id
  # @param [numeric] baseline_id baseline id
  # @return [EvmBaseline] evmbaselines
  def project_baseline(project_id, baseline_id)
    baselines = {}
    return unless Evmbaseline.exists?(project_id: project_id)
    baselines = if baseline_id.nil?
                  Evmbaseline.where(project_id: project_id).
                              order(created_on: :DESC)
                else
                  Evmbaseline.where(id: baseline_id)
                end
    baselines.first.evmbaselineIssues
  end

  # Get Issues of project.
  # Include descendants project.require inputted start date and due date.
  #
  # @note If the due date has not been entered, we will use the due date of the version
  # @param [Object] proj project
  # @return [Issue] issue object
  def project_issues(proj)
    Issue.cross_project_scope(proj, "descendants").
      where(SQL_COM.to_s)
  end

  # Get issues of version.
  # Include descendants project.require inputted start date and due date.
  #
  # @note If the due date has not been entered, we will use the due date of the version
  # @param [Numeric] proj_id project id
  # @param [Numeric] version_id fixed_version_id of project
  # @return [Issue] issue object
  def version_issues(proj_id, version_id)
    proj = Project.find(proj_id)
    Issue.cross_project_scope(proj, "descendants").
      where(SQL_COM.to_s).
      where(fixed_version_id: version_id)
  end

  # Get issues of assignee.
  # Include descendants project.require inputted start date and due date.
  #
  # @note If the due date has not been entered, we will use the due date of the version
  # @param [object] proj project object
  # @param [Numeric] assignee_id assignee of issue
  # @return [Issue] issue object
  def assignee_issues(proj, assignee_id)
    Issue.cross_project_scope(proj, "descendants").
      where(SQL_COM.to_s).
      where(assigned_to_id: assignee_id)
  end

  # Get issues of selected trackers.
  # Include descendants project.require inputted start date and due date.
  #
  # @note If the due date has not been entered, we will use the due date of the version
  # @param [object] proj project object
  # @param [Array] tracker_ids selected trackers
  # @return [Issue] issue object
  def tracker_issues(proj, tracker_ids)
    Issue.cross_project_scope(proj, "descendants").
      where(SQL_COM.to_s).
      where(tracker_id: tracker_ids)
  end

  # Get descendants issues
  #
  # @param [numeric] issue_id selected issue
  # @return [issue] descendants issues
  def parent_issues(issue_id)
    Issue.joins("JOIN #{Issue.table_name} ancestors" +
      " ON ancestors.root_id = #{Issue.table_name}.root_id" +
      " AND ancestors.lft <= #{Issue.table_name}.lft " +
      " AND ancestors.rgt >= #{Issue.table_name}.rgt ").
      where(SQL_COM.to_s).
      where(SQL_COM_ANC.to_s).
      where(:ancestors => {:id => issue_id})
  end

  # Get spent time of project.
  # Include descendants project.require inputted start date and due date.
  #
  # @param [Object] proj project
  # @return [Array] Two column,spent_on,sum of hours
  def project_costs(proj)
    Issue.cross_project_scope(proj, "descendants").
      select("spent_on, SUM(hours) AS sum_hours").
      where(SQL_COM.to_s).
      joins(:time_entries).
      group(:spent_on).
      collect {|issue| [issue.spent_on.to_date, issue.sum_hours] }
  end

  # Get spent time of version.
  # Include descendants project.require inputted start date and due date.
  #
  # @param [Numeric] proj_id project id
  # @param [Numeric] version_id fixed_version_id of project
  # @return [Issue] Two column,spent_on,sum of hours
  def version_costs(proj_id, version_id)
    proj = Project.find(proj_id)
    Issue.cross_project_scope(proj, "descendants").
      select("spent_on, SUM(hours) AS sum_hours").
      where(SQL_COM.to_s).
      where(fixed_version_id: version_id).
      joins(:time_entries).
      group(:spent_on).
      collect {|issue| [issue.spent_on.to_date, issue.sum_hours] }
  end

  # Get spent time of assignee.
  # Include descendants project.
  #
  # @param [object] proj project object
  # @param [Numeric] assignee_id of issue
  # @return [Issue] Two column,spent_on,sum of hours
  def assignee_costs(proj, assignee_id)
    Issue.cross_project_scope(proj, "descendants").
      select("spent_on, SUM(hours) AS sum_hours").
      where(SQL_COM.to_s).
      where(assigned_to_id: assignee_id).
      joins(:time_entries).
      group(:spent_on).
      collect {|issue| [issue.spent_on.to_date, issue.sum_hours] }
  end

  # Get spent time of selected trackers.
  # Include descendants project.
  #
  # @param [object] proj project object
  # @param [Array] tracker_ids selected trackers
  # @return [Array] Two column,spent_on,sum of hours
  def tracker_costs(proj, tracker_ids)
    Issue.cross_project_scope(proj, "descendants").
      select("spent_on, SUM(hours) AS sum_hours").
      where(SQL_COM.to_s).
      where(tracker_id: tracker_ids).
      joins(:time_entries).
      group(:spent_on).
      collect {|issue| [issue.spent_on.to_date, issue.sum_hours] }
  end

  # Get spent time of descendants issues
  #
  # @param [numeric] issue_id selected issue
  # @return [Array] Two column,spent_on,sum of hours
  def parent_issue_costs(issue_id)
    Issue.joins("JOIN #{Issue.table_name} ancestors" +
      " ON ancestors.root_id = #{Issue.table_name}.root_id" +
      " AND ancestors.lft <= #{Issue.table_name}.lft " +
      " AND ancestors.rgt >= #{Issue.table_name}.rgt ").
      select("spent_on, SUM(hours) AS sum_hours").
      where(SQL_COM.to_s).
      where(SQL_COM_ANC.to_s).
      where(:ancestors => {:id => issue_id}).
      joins(:time_entries).
      group(:spent_on).
      collect {|issue| [issue.spent_on.to_date, issue.sum_hours] }
  end

  # Get pair of project id and fixed version id.
  # sort by minimum due date of each version.
  #
  # @param [project] proj project object
  # @return [Array] project_id, fixed_version_id
  def project_varsion_id_pair(proj)
    Issue.cross_project_scope(proj, "descendants").
      select("project_id, fixed_version_id, MIN(due_date) as due_date").
      where(SQL_COM.to_s).
      where.not(fixed_version_id: nil).
      group(:project_id, :fixed_version_id).
      order("MIN(due_date)").
      collect {|issue| [issue.project_id, issue.fixed_version_id] }
  end

  # Get pair of project id and assinee id.
  # sort by assignee id.
  #
  # @param [project] proj project object
  # @return [issue] assigned_to_id
  def project_assignee_id_pair(proj)
    Issue.cross_project_scope(proj, "descendants").
      where(SQL_COM.to_s).
      select("assigned_to_id").
      group(:assigned_to_id).
      order(:assigned_to_id)
  end

  # Get imcomplete issuees on basis date.
  #
  # @note If the due date has not been entered, we will use the due date of the version
  # @param [Numeric] proj project id
  # @param [date] basis_date basis date
  # @return [Issue] issue object
  def incomplete_project_issues(proj, basis_date)
    Issue.cross_project_scope(proj, "descendants").
      where(SQL_COM.to_s).
      where("start_date <= ? AND (closed_on IS NULL OR closed_on > ?)", basis_date, basis_date.end_of_day)
  end
end
