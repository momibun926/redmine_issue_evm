require File.expand_path("issue_data_fetcher_scenario", __dir__)

# Tests of IssueDataFetcher (lib/issue_data_fetcher.rb), part 1: the issues the EVM is calculated from,
# the spent time and the lists the pages offer to select from. See IssueDataFetcherScenario for the data.
class IssueDataFetcherTest < ActiveSupport::TestCase
  include IssueDataFetcherScenario

  # ---- the issues the EVM is calculated from -------------------------------

  def test_evm_issues_are_the_issues_with_a_start_date_and_a_due_date_or_a_version_due_date
    assert_equal ids(:issue1, :issue2, :dated, :parent, :child1, :child2, :sub), sorted_ids(@fetcher.evm_issues(@project))
  end

  def test_evm_issues_include_the_sub_projects_and_leave_out_other_projects
    result = sorted_ids(@fetcher.evm_issues(@project))

    assert_includes result, @sub.id
    assert_not_includes result, @other.id
    assert_equal [@sub.id], sorted_ids(@fetcher.evm_issues(@sub_project))
  end

  def test_evm_issues_can_be_narrowed_by_a_condition
    assert_equal ids(:issue2, :parent, :child1, :child2),
                 sorted_ids(@fetcher.evm_issues(@project, { tracker_id: 2 }))
    assert_equal ids(:dated), sorted_ids(@fetcher.evm_issues(@project, { assigned_to_id: nil }))
  end

  def test_parent_issues_are_the_issue_and_its_descendants
    assert_equal ids(:parent, :child1, :child2), sorted_ids(@fetcher.parent_issues(@parent.id))
    assert_equal ids(:child1), sorted_ids(@fetcher.parent_issues(@child1.id))
    assert_equal ids(:issue1), sorted_ids(@fetcher.parent_issues(@issue1.id))
    assert_empty @fetcher.parent_issues(0)
  end

  def test_parent_issues_leave_out_the_issues_without_dates
    @child2.reload
    update_issue_columns(@child2, due_date: nil)

    assert_equal ids(:parent, :child1), sorted_ids(@fetcher.parent_issues(@parent.id))
  end

  # ---- spent time -----------------------------------------------------------

  def test_evm_costs_are_the_hours_of_each_day_of_the_counted_issues
    expected = { Date.new(2026, 1, 6) => 13.0, Date.new(2026, 1, 7) => 8.0, Date.new(2026, 1, 8) => 1.0,
                 Date.new(2026, 1, 13) => 4.0, Date.new(2026, 1, 19) => 3.0, Date.new(2026, 1, 21) => 2.0 }

    # 9h on the issue that is not counted and the unrelated project's time are left out
    assert_equal expected, @fetcher.evm_costs(@project)
  end

  def test_evm_costs_can_be_narrowed_by_a_condition
    assert_equal({ Date.new(2026, 1, 8) => 1.0 }, @fetcher.evm_costs(@project, { assigned_to_id: nil }))
    assert_equal({ Date.new(2026, 1, 13) => 4.0, Date.new(2026, 1, 19) => 3.0, Date.new(2026, 1, 21) => 2.0 },
                 @fetcher.evm_costs(@project, { tracker_id: 2 }))
  end

  def test_parent_issue_costs_are_the_hours_of_the_issue_and_its_descendants
    assert_equal({ Date.new(2026, 1, 19) => 3.0, Date.new(2026, 1, 21) => 2.0 }, @fetcher.parent_issue_costs(@parent.id))
    assert_equal({ Date.new(2026, 1, 19) => 3.0 }, @fetcher.parent_issue_costs(@child1.id))
    assert_equal({}, @fetcher.parent_issue_costs(0))
  end

  # ---- lists to select from ---------------------------------------------------

  def test_project_version_id_pairs_are_the_project_and_version_of_the_counted_issues
    assert_equal [[@project.id, @release.id], [@project.id, @late.id]].sort, @fetcher.project_varsion_id_pair(@project).sort
  end

  def test_assignee_ids_include_nil_for_no_assignee
    assert_equal [nil, 2, 11], @fetcher.assignee_ids(@project).sort_by(&:to_i)
  end

  def test_selectable_assignee_list_maps_the_name_to_the_id
    list = @fetcher.selectable_assignee_list(@project)

    assert_equal([["no assigned", nil], ["John Smith", 2], ["B Team", 11]],
                 list.map { |name, id| [name.to_s, id] }.sort_by { |_name, id| id.to_i })
  end

  def test_selectable_version_list
    list = @fetcher.selectable_version_list(@project).map { |issue| [issue.fixed_version_id, issue.name] }

    assert_equal [[@release.id, "Release 1"], [@late.id, "Late"]].sort, list.sort
  end

  def test_selectable_tracker_list
    list = @fetcher.selectable_tracker_list(@project).map { |issue| [issue.tracker_id, issue.name] }

    assert_equal [[1, "Bug"], [2, "Feature request"]], list.sort
  end

  def test_selectable_parent_issues_are_the_top_level_issues_of_the_project_that_have_children
    assert_equal([[@parent.id, "parent"]], @fetcher.selectable_parent_issues_list(@project).map { |i| [i.id, i.subject] })
  end

  def test_assignee_name
    assert_equal "no assigned", @fetcher.assignee_name(nil)
    assert_equal "no assigned", @fetcher.assignee_name("")
    assert_equal User.find(2), @fetcher.assignee_name(2)
    assert_equal Group.find(11), @fetcher.assignee_name(11)
    assert_nil @fetcher.assignee_name(0)
  end
end
