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
    issues = proj.issues.where( "start_date IS NOT NULL AND due_date IS NOT NULL")
  end


  def project_costs proj
    costs = proj.issues.select("MAX(spent_on) AS spent_on, SUM(hours) AS sum_hours").
              where( "start_date IS NOT NULL AND due_date IS NOT NULL" ).
              joins(:time_entries).
              group("spent_on").collect { |issue| [issue.spent_on, issue.sum_hours] }
  end


  def version_issues proj, version_id
    issues = proj.issues.where( "start_date IS NOT NULL AND due_date IS NOT NULL AND fixed_version_id = ? ", version_id)
  end 


  def version_costs proj, version_id
    costs = proj.issues.where( "fixed_version_id = ? ", version_id).
              select("MAX(spent_on) AS spent_on, SUM(hours) AS sum_hours").
              joins(:time_entries).
              group("spent_on").collect { |issue| [issue.spent_on, issue.sum_hours] }
  end 


  def include_sub_project_issues proj
    id = sub_project_id_array proj
    issues = proj.issues.cross_project_scope(proj, "all").
               where( "start_date IS NOT NULL AND due_date IS NOT NULL AND project_id IN (?)",id)
  end


  def include_sub_project_costs proj
    id = sub_project_id_array proj
    costs = proj.issues.cross_project_scope(proj, "all").
              where( "start_date IS NOT NULL AND due_date IS NOT NULL AND issues.project_id IN (?)",id).
              select("MAX(spent_on) AS spent_on, SUM(hours) AS sum_hours").
              joins(:time_entries).
              group("spent_on").collect { |issue| [issue.spent_on, issue.sum_hours] }
  end


  def sub_project_id_array proj
    id = []
    proj.children.each do |sub|
      id << sub.id
    end
    id << proj.id
  end


end
