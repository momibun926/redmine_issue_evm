module IssueDataFetcher
  # Lists the pages offer to select from (assignee, version, tracker, parent issue).
  # Mixed into IssueDataFetcher: the methods use its query helpers (evm_target_condition and others).
  module SelectableLists
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

    # user name
    # include nil. When userid is nil, no assigned name.
    #
    # @param [Numeric] id assignee id or user group id
    # @return [String] assignee name or user group name
    def assignee_name(id)
      return l(:no_assignee) if id.blank?

      User.find_by(id: id) || Group.find_by(id: id)
    end
  end
end
