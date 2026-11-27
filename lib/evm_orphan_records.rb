# Records of the plugin left behind by projects deleted before
# EvmProjectPatch existed: settings, baselines and reports whose project
# no longer exists, and baseline issues whose baseline no longer exists
# (or is one of those baselines).
#
# Used by the rake tasks in lib/tasks/redmine_issue_evm.rake.
module EvmOrphanRecords
  module_function

  # Number of records to delete, for each table.
  #
  # @return [Hash{String => Integer}]
  def counts
    scopes.transform_values(&:count)
  end

  # Delete the records in one transaction.
  #
  # @return [Hash{String => Integer}] number of records deleted, for each table
  def delete!
    ActiveRecord::Base.transaction do
      scopes.transform_values(&:delete_all)
    end
  end

  # Baseline issues come first: their scope looks at which baselines
  # survive, so it must be built before the baselines are deleted.
  def scopes
    baseline_ids = without_project(Evmbaseline).pluck(:id)
    { "evmbaseline_issues" => baseline_issues_without_baseline(baseline_ids),
      "evmbaselines" => Evmbaseline.where(id: baseline_ids),
      "evmsettings" => without_project(Evmsetting),
      "project_evmreports" => without_project(ProjectEvmreport) }
  end

  def without_project(model)
    model.where.not(project_id: Project.select(:id)).or(model.where(project_id: nil))
  end

  def baseline_issues_without_baseline(orphan_baseline_ids)
    surviving = Evmbaseline.where.not(id: orphan_baseline_ids).select(:id)
    EvmbaselineIssue.where.not(evmbaseline_id: surviving).or(EvmbaselineIssue.where(evmbaseline_id: nil))
  end
  private_class_method :scopes, :without_project, :baseline_issues_without_baseline
end
