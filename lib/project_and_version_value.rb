module ProjectAndVersionValue

  def project_baseline project_id, baseline_id
    baselines = {}
    if Evmbaseline.exists?(:project_id => project_id)
      if baseline_id.nil?
        baselines = Evmbaseline.where("project_id = ? ", project_id).order("created_on DESC").first.evmbaselineIssues
      else
        baselines = Evmbaseline.where("id = ? ", baseline_id).first.evmbaselineIssues
      end
    end
    baselines
  end


  def project_issues proj
    issues = Issue.cross_project_scope(proj, "descendants").
              where( "start_date IS NOT NULL AND due_date IS NOT NULL")
  end


  def project_costs proj
    costs = Issue.cross_project_scope(proj, "descendants").
              select("MAX(spent_on) AS spent_on, SUM(hours) AS sum_hours").
              where( "start_date IS NOT NULL AND due_date IS NOT NULL" ).
              joins(:time_entries).
              group("spent_on").collect { |issue| [issue.spent_on, issue.sum_hours] }
  end


  def version_issues proj, version_id
    issues = Issue.cross_project_scope(proj, "descendants").
              where( "start_date IS NOT NULL AND due_date IS NOT NULL AND fixed_version_id = ? ", version_id)
  end


  def version_costs proj, version_id
    costs = Issue.cross_project_scope(proj, "descendants").
              where( "fixed_version_id = ? ", version_id).
              select("MAX(spent_on) AS spent_on, SUM(hours) AS sum_hours").
              joins(:time_entries).
              group("spent_on").collect { |issue| [issue.spent_on, issue.sum_hours] }
  end


  def incomplete_project_issues proj, basis_date
    issues = Issue.cross_project_scope(proj, "descendants").
              where( "start_date IS NOT NULL AND start_date <= ? AND due_date IS NOT NULL AND (closed_on IS NULL OR closed_on > ?)", basis_date, basis_date)
  end


end
