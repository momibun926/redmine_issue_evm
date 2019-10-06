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

  # Get issues of EVM for PV and EV.
  # Include descendants project.require inputted start date and due date.
  # for use calculate PV and EV.
  #
  # @note If the due date has not been entered, we will use the due date of the version
  # @param [object] proj project object
  # @param [hush] condition fieldname(symbol) conditon value
  # @return [Issue] issue object
  def evm_issues(proj, condition = " 1 = 1 ")
    Issue.cross_project_scope(proj, "descendants").
      where(SQL_COM.to_s).
      where(condition)
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
  def evm_costs(proj, condition = " 1 = 1 ")
    Issue.cross_project_scope(proj, "descendants").
      select("spent_on, SUM(hours) AS sum_hours").
      where(SQL_COM.to_s).
      where(condition).
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
      select(:project_id, :fixed_version_id).
      where(SQL_COM.to_s).
      where.not(fixed_version_id: nil).
      group(:project_id, :fixed_version_id).
      collect {|issue| [issue.project_id, issue.fixed_version_id] }
  end

  # Get assinee ids in project.
  # sort by assignee id.
  #
  # @param [project] proj project object
  # @return [issue] assigned_to_id
  def project_assignee_id_pair(proj)
    Issue.cross_project_scope(proj, "descendants").
      select(:assigned_to_id).
      where(SQL_COM.to_s).
      group(:assigned_to_id).
      order(:assigned_to_id)
  end

  # Selectable assinee list.
  # sort by assignee id.
  #
  # @param [project] proj project object
  # @return [issue] assigned_to_id
  def selectable_assignee_list(proj)
    issues = project_assignee_id_pair proj
    selectable_list = {}
    issues.each do |issue|
      assinee_name  = issue.assigned_to_id.nil? ? l(:no_assignee) : User.find(issue.assigned_to_id).name
      selectable_list[assinee_name] = issue.assigned_to_id
    end
    selectable_list
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
      where("start_date <= ? AND (closed_on IS NULL OR closed_on > ?)",
            basis_date, basis_date.end_of_day)
  end
end
