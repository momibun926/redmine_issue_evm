# Get data of Calculation EVM
#
module ProjectAndVersionValue
  # Calculation common condition of issue's select
  SQL_COM = '(start_date IS NOT NULL AND due_date IS NOT NULL) OR (start_date IS NOT NULL AND due_date IS NULL AND fixed_version_id IS NOT NULL)'
  # Condition for filtering with an outer joined table
  SQL_COM_FILTER = '((start_date IS NOT NULL) AND (due_date IS NOT NULL OR effective_date IS NOT NULL))'

  # Get Issues of Baseline.(start date, due date, estimated hours)
  # When baseline_id is nil,latest baseline of project.
  #
  # @param [numeric] project_id project id
  # @param [numeric] baseline_id baseline id
  # @return [EvmBaseline] evmbaselines
  def project_baseline(project_id, baseline_id)
    baselines = {}
    return unless Evmbaseline.exists?(project_id: project_id)
    if baseline_id.nil?
      baselines = Evmbaseline.where('project_id = ? ', project_id).order('created_on DESC')
    else
      baselines = Evmbaseline.where('id = ? ', baseline_id)
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
    Issue.cross_project_scope(proj, 'descendants')
      .includes(:fixed_version).where("#{SQL_COM_FILTER}")
      .references(:fixed_version)
      .where("#{SQL_COM}")
  end

  # Get spent time of project.
  # Include descendants project.require inputted start date and due date.
  #
  # @param [Object] proj project
  # @return [Array] Two column,spent_on,sum of hours
  def project_costs(proj)
    Issue.cross_project_scope(proj, 'descendants')
      .select('spent_on, SUM(hours) AS sum_hours')
      .where("#{SQL_COM}")
      .joins(:time_entries)
      .group(:spent_on)
      .collect { |issue| [issue.spent_on.to_date, issue.sum_hours] }
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
    Issue.cross_project_scope(proj, 'descendants')
      .includes(:fixed_version).where("#{SQL_COM_FILTER}")
      .references(:fixed_version)
      .where(fixed_version_id: version_id)
  end

  # Get spent time of version.
  # Include descendants project.require inputted start date and due date.
  #
  # @param [Numeric] proj_id project id
  # @param [Numeric] version_id fixed_version_id of project
  # @return [Issue] Two column,spent_on,sum of hours
  def version_costs(proj_id, version_id)
    proj = Project.find(proj_id)
    Issue.cross_project_scope(proj, 'descendants')
      .select('spent_on, SUM(hours) AS sum_hours')
      .where(fixed_version_id: version_id)
      .joins(:time_entries)
      .group(:spent_on)
      .collect { |issue| [issue.spent_on.to_date, issue.sum_hours] }
  end

  # Get pair of project id and fixed version id.
  # sort by minimum due date of each version.
  #
  # @param [project] proj project object
  # @return [Array] project_id, fixed_version_id
  def project_varsion_id_pair(proj)
    Issue.cross_project_scope(proj, 'descendants')
      .select('project_id, fixed_version_id, MIN(due_date) as due_date')
      .where.not(fixed_version_id: nil)
      .group(:project_id, :fixed_version_id)
      .order('MIN(due_date)')
      .collect { |issue| [issue.project_id, issue.fixed_version_id] }
  end

  # Get imcomplete issuees on basis date.
  #
  # @note If the due date has not been entered, we will use the due date of the version
  # @param [Numeric] proj project id
  # @param [date] basis_date basis date
  # @return [Issue] issue object
  def incomplete_project_issues(proj, basis_date)
    Issue.cross_project_scope(proj, 'descendants')
      .includes(:fixed_version).where("#{SQL_COM_FILTER} AND start_date <= ? AND (closed_on IS NULL OR closed_on > ?)", basis_date, basis_date.end_of_day)
      .references(:fixed_version)
      .where("#{SQL_COM}", basis_date)
  end
end
