require File.expand_path("../../functional/evm_functional_test_helper", __dir__)

# Data for the tests of IssueDataFetcher (lib/issue_data_fetcher.rb), which run against the database:
# which issues the EVM is calculated from, the spent time, the lists the
# pages offer to select from, and the counts shown on the main page.
#
# The data (dates are fixed, so nothing depends on the day the tests run):
#
#   project "EVM scenario" (Release 1 due 2026-01-16, "Late" due 2026-02-06,
#   "No date" without a due date) with its sub project "Sub"
#
#   issue1   01-05 .. 01-09  Bug      John Smith  Release 1   (from the scenario helper)
#   issue2   01-12 .. 01-16  Feature  John Smith              (from the scenario helper)
#   dated    start only      Bug      nobody      Late        -> counted, its version has a due date
#   undated  start only      Bug      John Smith              -> not counted: no due date at all
#   nodate   start only      Bug      John Smith  No date     -> not counted: the version has no due date
#   no_start due date only   Bug      John Smith              -> not counted: no start date
#   parent   01-19 .. 01-23  Feature  John Smith              with the children
#   child1   01-19 .. 01-20  Feature  John Smith  3h spent
#   child2   01-21 .. 01-23  Feature  John Smith  2h spent
#   sub      01-06 .. 01-08  Bug      B Team (group)  5h spent   (in the sub project)
#   other    01-06 .. 01-08  Bug      John Smith  (in an unrelated project)
module IssueDataFetcherScenario
  # What the controllers and CalculateEv get by including IssueDataFetcher
  class Fetcher
    include IssueDataFetcher
    include Redmine::I18n
  end

  def self.included(base)
    base.include EvmFunctionalTestSupport
  end

  def setup
    @fetcher = Fetcher.new
    create_scenario
  end

  private

  def create_scenario
    @project = create_evm_scenario_project
    @sub_project = create_project("Sub", "evm-sub", parent_id: @project.id)
    @other_project = create_project("Other", "evm-other")
    @project = Project.find(@project.id) # its nested set values changed with the sub project
    @release = @issue1.fixed_version
    @late = Version.create!(project: @project, name: "Late", effective_date: Date.new(2026, 2, 6))
    no_date = Version.create!(project: @project, name: "No date")
    create_scenario_issues(no_date)
    create_children_and_other_projects_issues
  end

  def create_project(name, identifier, attributes = {})
    project = Project.create!({ name: name, identifier: identifier, tracker_ids: [1, 2],
                                enabled_module_names: %w[issue_tracking time_tracking] }.merge(attributes))
    Member.create!(project: project, user_id: 2, role_ids: [1])
    project
  end

  def create_scenario_issues(no_date)
    @issue1.reload
    @issue2.reload
    @dated = create_scenario_issue(@project, "dated", [Date.new(2026, 1, 8), nil], 6, fixed_version: @late, assigned_to_id: nil)
    @undated = create_scenario_issue(@project, "undated", [Date.new(2026, 1, 8), nil], 6)
    @nodate = create_scenario_issue(@project, "nodate", [Date.new(2026, 1, 8), nil], 6, fixed_version: no_date)
    @no_start = create_scenario_issue(@project, "no start", [nil, Date.new(2026, 1, 8)], 6)
    create_time_entry(@dated, Date.new(2026, 1, 8), 1)
    create_time_entry(@undated, Date.new(2026, 1, 8), 9)
  end

  def create_children_and_other_projects_issues
    @parent = create_scenario_issue(@project, "parent", [Date.new(2026, 1, 19), Date.new(2026, 1, 23)], 0, tracker_id: 2)
    @child1 = create_scenario_issue(@project, "child 1", [Date.new(2026, 1, 19), Date.new(2026, 1, 20)], 8,
                                    parent_issue_id: @parent.id, tracker_id: 2)
    @child2 = create_scenario_issue(@project, "child 2", [Date.new(2026, 1, 21), Date.new(2026, 1, 23)], 12,
                                    parent_issue_id: @parent.id, tracker_id: 2)
    @sub = create_scenario_issue(@sub_project, "sub", [Date.new(2026, 1, 6), Date.new(2026, 1, 8)], 10, assigned_to_id: nil)
    update_issue_columns(@sub, assigned_to_id: 11) # a group, which a project member cannot be set through validation
    @other = create_scenario_issue(@other_project, "other", [Date.new(2026, 1, 6), Date.new(2026, 1, 8)], 10)
    create_time_entry(@child1, Date.new(2026, 1, 19), 3)
    create_time_entry(@child2, Date.new(2026, 1, 21), 2)
    create_time_entry(@sub, Date.new(2026, 1, 6), 5)
    create_time_entry(@other, Date.new(2026, 1, 6), 7)
  end

  # A journal of the issue written at the given time; with a note, or with a change of the done ratio ([old, new])
  def create_journal(issue, created_on, notes: nil, done_ratio: nil)
    journal = Journal.new(journalized: issue, user_id: 2, notes: notes, created_on: created_on)
    if done_ratio
      journal.details << JournalDetail.new(property: "attr", prop_key: "done_ratio",
                                           old_value: done_ratio.first, value: done_ratio.last)
    end
    journal.save!
    journal
  end

  # Ids of the named issues, sorted
  def ids(*names)
    names.map { |name| instance_variable_get("@#{name}").id }.sort
  end

  def sorted_ids(issues)
    issues.map(&:id).sort
  end
end
