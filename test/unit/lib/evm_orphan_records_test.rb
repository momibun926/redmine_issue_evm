require File.expand_path("../../test_helper", __dir__)
require File.expand_path("../evm_plugin_records_helper", __dir__)
require "rake"

# Records left behind by projects deleted before EvmProjectPatch, and the
# rake tasks that count and delete them.
class EvmOrphanRecordsTest < ActiveSupport::TestCase
  include EvmPluginRecordsHelper

  RAKE_FILE = File.expand_path("../../../lib/tasks/redmine_issue_evm.rake", __dir__)

  def setup
    @deleted = Project.create!(name: "EVM deleted", identifier: "evm-deleted")
    @kept = Project.create!(name: "EVM kept", identifier: "evm-kept")
    [@deleted, @kept].each { |project| create_plugin_records(project) }
    # Deleted the way Redmine did before EvmProjectPatch: the plugin's
    # records stay.
    Project.where(id: @deleted.id).delete_all
  end

  def test_counts_the_records_of_deleted_projects
    assert_equal expected_orphans, EvmOrphanRecords.counts
  end

  def test_counts_baseline_issues_whose_baseline_was_deleted
    EvmbaselineIssue.create!(evmbaseline_id: 0, issue_id: 1)
    EvmbaselineIssue.create!(evmbaseline_id: nil, issue_id: 1)

    assert_equal 5, EvmOrphanRecords.counts["evmbaseline_issues"]
  end

  def test_counts_records_without_a_project
    Evmsetting.find_by(project_id: @kept.id).update!(project_id: nil)

    assert_equal 2, EvmOrphanRecords.counts["evmsettings"]
  end

  def test_delete_deletes_only_the_records_of_deleted_projects
    assert_equal expected_orphans, EvmOrphanRecords.delete!

    assert_equal [0, 0, 0, 0], plugin_record_counts(@deleted)
    assert_equal [1, 2, 1, 3], plugin_record_counts(@kept)
    assert_equal({ "evmbaseline_issues" => 0, "evmbaselines" => 0, "evmsettings" => 0, "project_evmreports" => 0 },
                 EvmOrphanRecords.counts)
  end

  def test_count_task_shows_the_counts_and_does_not_delete
    output = run_task("redmine_issue_evm:orphans:count")

    assert_includes output, "evmbaseline_issues: 3\n"
    assert_includes output, "evmbaselines: 2\n"
    assert_includes output, "redmine_issue_evm:orphans:delete"
    assert_equal expected_orphans, EvmOrphanRecords.counts
  end

  def test_delete_task_deletes_and_shows_the_numbers
    output = run_task("redmine_issue_evm:orphans:delete")

    assert_includes output, "evmbaseline_issues: 3 deleted\n"
    assert_includes output, "project_evmreports: 1 deleted\n"
    assert_equal [0, 0, 0, 0], plugin_record_counts(@deleted)
  end

  private

  def expected_orphans
    { "evmbaseline_issues" => 3, "evmbaselines" => 2, "evmsettings" => 1, "project_evmreports" => 1 }
  end

  # Load only the plugin's rake file, with a stand-in for :environment
  # (the test already runs inside Rails).
  def run_task(name)
    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    load RAKE_FILE
    capture_io { Rake::Task[name].invoke }.first
  end
end
