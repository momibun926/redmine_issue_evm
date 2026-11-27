# Creates and counts the plugin's records of a project, for the tests of
# EvmProjectPatch and EvmOrphanRecords.
module EvmPluginRecordsHelper
  # One setting, two baselines with three baseline issues in all, one report.
  def create_plugin_records(project)
    Evmsetting.create!(project_id: project.id, user_id: 2, etc_method: "method2", basis_hours: 8,
                       threshold_spi: 0.9, threshold_cpi: 0.9, threshold_cr: 0.9, region: "jp")
    baseline_ids[project.id] = Array.new(2) do |i|
      baseline = Evmbaseline.create!(project_id: project.id, subject: "Baseline #{i}")
      (i + 1).times { |n| EvmbaselineIssue.create!(evmbaseline_id: baseline.id, issue_id: n + 1) }
      baseline.id
    end
    ProjectEvmreport.create!(project_id: project.id, status_date: Date.new(2026, 1, 8), report_text: "Report")
  end

  # [settings, baselines, reports, baseline issues] of the project.
  # Baseline issues are counted by the baseline ids recorded when they were
  # created, so that those of deleted baselines are still found.
  def plugin_record_counts(project)
    [Evmsetting.where(project_id: project.id).count,
     Evmbaseline.where(project_id: project.id).count,
     ProjectEvmreport.where(project_id: project.id).count,
     EvmbaselineIssue.where(evmbaseline_id: baseline_ids[project.id]).count]
  end

  private

  def baseline_ids
    @baseline_ids ||= {}
  end
end
