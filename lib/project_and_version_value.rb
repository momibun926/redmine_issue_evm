# Get data of Calculation EVM
module ProjectAndVersionValue
  # Baselines.
  # When baseline_id is nil,latest baseline of project.
  #
  # @param [numeric] project_id project id
  # @param [numeric] baseline_id baseline id
  # @return [EvmBaseline] evmbaselines
  def project_baseline(project_id, baseline_id)
    baselines = {}
    if Evmbaseline.exists?(project_id: project_id)
      if baseline_id.nil?
        baselines = Evmbaseline.where('project_id = ? ', project_id).order('created_on DESC').first.evmbaselineIssues
      else
        baselines = Evmbaseline.where('id = ? ', baseline_id).first.evmbaselineIssues
      end
    end
    baselines
  end

  # Get Issues of project.
  # Include descendants project.require inputted start date and due date.
  #
  # @param [Object] proj project
  # @return [Issue] issue object
  def project_issues(proj)
    Issue.cross_project_scope(proj, 'descendants')
      .where('start_date IS NOT NULL AND due_date IS NOT NULL')
  end

  # Get spent time of project.
  # Include descendants project.require inputted start date and due date.
  #
  # @param [Object] proj project
  # @return [Array] Two column,spent_on,sum of hours
  def project_costs(proj)
    Issue.cross_project_scope(proj, 'descendants')
      .select('MAX(spent_on) AS spent_on, SUM(hours) AS sum_hours')
      .where('start_date IS NOT NULL AND due_date IS NOT NULL')
      .joins(:time_entries)
      .group('spent_on').collect { |issue| [issue.spent_on, issue.sum_hours] }
  end

  # Get issues of version.
  # Include descendants project.require inputted start date and due date.
  #
  # @param [Numeric] proj_id project id
  # @param [Numeric] version_id fixed_version_id of project
  # @return [Issue] issue object
  def version_issues(proj_id, version_id)
    proj = Project.find(proj_id)
    Issue.cross_project_scope(proj, 'descendants')
      .where('start_date IS NOT NULL AND due_date IS NOT NULL AND fixed_version_id = ? ', version_id)
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
      .select('MAX(spent_on) AS spent_on, SUM(hours) AS sum_hours')
      .where('start_date IS NOT NULL AND due_date IS NOT NULL AND fixed_version_id = ? ', version_id)
      .joins(:time_entries)
      .group('spent_on').collect { |issue| [issue.spent_on, issue.sum_hours] }
  end

  # Get imcomplete issuees on basis date.
  #
  # @param [Numeric] proj project id
  # @param [date] basis_date basis date
  # @return [Issue] issue object
  def incomplete_project_issues(proj, basis_date)
    Issue.cross_project_scope(proj, 'descendants')
      .where('start_date IS NOT NULL AND start_date <= ? AND due_date IS NOT NULL AND (closed_on IS NULL OR closed_on > ?)', basis_date, basis_date.to_time.end_of_day)
  end

  # Get pair of project id and fixed version id.
  #
  # @param [project] proj project object
  # @return [Array] project_id, fixed_version_id
  def project_varsion_id_pair(proj)
    Issue.cross_project_scope(proj, 'descendants')
      .where('start_date IS NOT NULL AND due_date IS NOT NULL AND fixed_version_id IS NOT NULL')
      .joins(:fixed_version).order('effective_date ASC')
      .uniq.pluck(:project_id, :fixed_version_id)
  end
end
