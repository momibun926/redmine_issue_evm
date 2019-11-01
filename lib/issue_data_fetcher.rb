# Issue data fetcher
# This module is a function to collect ISSUE records necessary to calculate EVM
# It also collects a selectable list that is optionally specified
#
module IssueDataFetcher
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
  
  # Get issues of EVM for PV and EV.
  # Include descendants project.require inputted start date and due date.
  # for use calculate PV and EV.a
  #
  # @param [object] proj project object
  # @param [hush] condition fieldname(symbol) conditon value
  # @return [Issue] issue object
  def evm_issues(proj, condition = " 1 = 1 ")
    Issue.cross_project_scope(proj, "descendants").
      where(SQL_COM.to_s).
      where(condition)
  end

  # Get descendants parent issue
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
      where(:ancestors => { :id => issue_id })
  end

  # Get spent time of project.
  # Include descendants project.require inputted start date and due date.
  #
  # @param [Object] proj project
  # @return [hash] Two column,spent_on,sum of hours
  def evm_costs(proj, condition = " 1 = 1 ")
    Issue.cross_project_scope(proj, "descendants").
      where(SQL_COM.to_s).
      where(condition).
      joins(:time_entries).
      group(:spent_on).sum(:hours)
  end

  # Get spent time of parent issue
  #
  # @param [numeric] issue_id selected issue
  # @return [hash] Two column,spent_on,sum of hours
  def parent_issue_costs(issue_id)
    Issue.joins("JOIN #{Issue.table_name} ancestors" +
      " ON ancestors.root_id = #{Issue.table_name}.root_id" +
      " AND ancestors.lft <= #{Issue.table_name}.lft " +
      " AND ancestors.rgt >= #{Issue.table_name}.rgt ").
      where(SQL_COM.to_s).
      where(SQL_COM_ANC.to_s).
      where(:ancestors => { :id => issue_id }).
      joins(:time_entries).
      group(:spent_on).sum(:hours)
  end

  # Get pair of project id and fixed version id.
  #
  # @param [project] proj project object
  # @return [Array] project_id, fixed_version_id
  def project_varsion_id_pair(proj)
    Issue.cross_project_scope(proj, "descendants").
      where(SQL_COM.to_s).
      where.not(fixed_version_id: nil).
      distinct(:project_id, :fixed_version_id).
      pluck(:project_id, :fixed_version_id)
  end

  # Get assinee ids in project.
  # sort by assignee id.
  #
  # @param [project] proj project object
  # @return [issue] assigned_to_id
  def assignee_ids(proj)
    Issue.cross_project_scope(proj, "descendants").
      where(SQL_COM.to_s).
      distinct(:assigned_to_id).
      pluck(:assigned_to_id)
  end

  # Selectable assinee list.
  # sort by assignee id.
  #
  # @param [project] proj project object
  # @return [hash] assigenee name, assigned_to_id
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
  # @param [project] proj project object
  # @return [issue] fixed_version_id, versions.name
  def selectable_version_list(proj)
    Issue.cross_project_scope(proj, "descendants").
      select(:fixed_version_id, "versions.name").
      where(SQL_COM.to_s).
      joins(:fixed_version).
      group(:fixed_version_id, "versions.name")
  end

  # Selectable tracker list
  #
  # @param [project] proj project object
  # @return [issue] tracker_id, name
  def selectable_tracker_list(proj)
    Issue.cross_project_scope(proj, "descendants").
      select(:tracker_id, "trackers.name").
      where(SQL_COM.to_s).
      joins(:tracker).
      group(:tracker_id, "trackers.name")
  end

  # Selectable parent issue list
  #
  # @param [project] proj project object
  # @return [issue] parent issues
  def selectable_parent_issues_list(proj)
    Issue.where(project_id: proj.id).
      select(:id, :subject).
      where(parent_id: nil).
      where("( rgt - lft ) > 1")
  end

  # Get imcomplete issuees on basis date.
  #
  # @param [project] proj project id
  # @param [date] basis_date basis date
  # @return [Issue] issue object
  def incomplete_project_issues(proj, basis_date)
    Issue.cross_project_scope(proj, "descendants").
      where(SQL_COM.to_s).
      where("start_date <= ? AND (closed_on IS NULL OR closed_on > ?)",
            basis_date, basis_date.end_of_day)
  end

  # project metrics
  # collect basic information of project. 
  #
  # @param [project] proj project object
  # @param [calculateEVM] evm calculate EVN class instance
  # @return [hash] project metrics 
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
    metrics[:state] = evm.pv.state
    # plan due date difference
    metrics[:due_date_difference] = (evm.pv.basis_date - evm.pv.due_date).to_i
    # return
    metrics
  end

  # amount of issue in project
  #
  # @return [numeric] array id total issues
  def total_issue_amount(proj)
    Issue.cross_project_scope(proj, "descendants").pluck(:id)
  end

  # amount of issue in target
  #
  # @return [numeric] array id of target issues
  def target_issue_amount(proj)
    Issue.cross_project_scope(proj, "descendants").where(SQL_COM.to_s).pluck(:id)
  end

  # amount of issue in version
  #
  # @param [project] proj project object
  # @return [hash] amount of issues. each versions.
  def count_version_list(proj)
    Issue.cross_project_scope(proj, "descendants").
      where(SQL_COM.to_s).
      joins(:fixed_version).
      group("versions.name").count
  end

  # amount of issue in assignee
  #
  # @param [project] proj project object
  # @return [hash] count of issues. each assignees (include noassign).
  def count_assignee_list(proj)
    issues = Issue.cross_project_scope(proj, "descendants").
               where(SQL_COM.to_s).
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
  # @param [project] proj project object
  # @return [hash] count of issues. each trackers.
  def count_tracker_list(proj)
    Issue.cross_project_scope(proj, "descendants").
      where(SQL_COM.to_s).
      joins(:tracker).
      group("trackers.name").count
  end

  # user name
  # include nil. When userid is nil, no assigned name.
  #
  # @param [numeric] id assignee id or user group id
  # @return [string] assignee name or user group name
  def assignee_name(id)
    assigneee = User.find_by(id: id) || Group.find_by(id: id)
    assignee_name = id.blank? ? l(:no_assignee) : assigneee.name
  end
end
