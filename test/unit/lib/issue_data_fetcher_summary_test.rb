require File.expand_path("issue_data_fetcher_scenario", __dir__)

# Tests of IssueDataFetcher (lib/issue_data_fetcher.rb), part 2: incomplete issues, project metrics and
# counts, the issue tree and journals, and the difference from a baseline.
# See IssueDataFetcherScenario for the data.
class IssueDataFetcherSummaryTest < ActiveSupport::TestCase
  include IssueDataFetcherScenario

  # ---- incomplete issues ------------------------------------------------------

  def test_incomplete_issues_are_the_open_issues_due_by_the_basis_date_earliest_due_date_first
    expected = [@sub, @issue1, @child1].map(&:id)

    assert_equal expected, @fetcher.incomplete_project_issues(@project, Date.new(2026, 1, 20)).map(&:id)
  end

  def test_incomplete_issues_leave_out_the_issues_due_after_the_basis_date
    assert_equal ids(:sub), @fetcher.incomplete_project_issues(@project, Date.new(2026, 1, 8)).map(&:id)
    assert_empty @fetcher.incomplete_project_issues(@project, Date.new(2026, 1, 7))
  end

  def test_an_issue_closed_before_the_basis_date_is_complete_and_one_closed_after_it_is_not
    update_issue_columns(@sub, closed_on: Time.utc(2026, 1, 12, 3))
    update_issue_columns(@issue1, closed_on: Time.utc(2026, 1, 25, 3))

    assert_equal ids(:issue1, :child1), @fetcher.incomplete_project_issues(@project, Date.new(2026, 1, 20)).map(&:id).sort
  end

  def test_an_issue_closed_on_the_basis_date_is_complete
    update_issue_columns(@child1, closed_on: Time.utc(2026, 1, 20, 12))

    assert_not_includes @fetcher.incomplete_project_issues(@project, Date.new(2026, 1, 20)).map(&:id), @child1.id
  end

  def test_an_issue_with_100_percent_done_is_complete
    update_issue_columns(@issue1, done_ratio: 100)

    assert_not_includes @fetcher.incomplete_project_issues(@project, Date.new(2026, 1, 20)).map(&:id), @issue1.id
  end

  # ---- project metrics and counts --------------------------------------------

  def test_total_and_target_issue_amount_are_the_ids_of_all_and_of_the_counted_issues
    assert_equal ids(:issue1, :issue2, :dated, :undated, :nodate, :no_start, :parent, :child1, :child2, :sub),
                 @fetcher.total_issue_amount(@project).sort
    assert_equal ids(:issue1, :issue2, :dated, :parent, :child1, :child2, :sub),
                 @fetcher.target_issue_amount(@project).sort
  end

  def test_project_metrics
    evm = CalculateEvmLogic::CalculateEvm.new(nil, @fetcher.evm_issues(@project), @fetcher.evm_costs(@project),
                                              basis_date: Date.new(2026, 1, 20), working_hours: 8, forecast: true,
                                              etc_method: "method2", exclude_holiday: false, region: nil)

    metrics = @fetcher.project_metrics(@project, evm)

    assert_equal %i[total_issue_ids target_issue_ids plan_start_date plan_due_date actual_start_date state
                    due_date_difference], metrics.keys
    assert_equal [10, 7], [metrics[:total_issue_ids], metrics[:target_issue_ids]]
    assert_equal [Date.new(2026, 1, 5), Date.new(2026, 2, 6), Date.new(2026, 1, 6)],
                 [metrics[:plan_start_date], metrics[:plan_due_date], metrics[:actual_start_date]]
    assert_equal [%i[progress within_duration], 18], [metrics[:state], metrics[:due_date_difference]]
  end

  def test_count_version_list
    assert_equal({ "Release 1" => 1, "Late" => 1 }, @fetcher.count_version_list(@project))
  end

  def test_count_assignee_list
    counts = @fetcher.count_assignee_list(@project).map { |name, count| [name.to_s, count] }

    assert_equal [["B Team", 1], ["John Smith", 5], ["no assigned", 1]], counts.sort
  end

  def test_count_tracker_list
    assert_equal({ "Bug" => 3, "Feature request" => 4 }, @fetcher.count_tracker_list(@project))
  end

  # ---- issue tree and journals -----------------------------------------------

  def test_issue_child_is_the_descendant_closed_last
    update_issue_columns(@child1, closed_on: Time.utc(2026, 1, 20, 3))
    update_issue_columns(@child2, closed_on: Time.utc(2026, 1, 23, 3))
    update_issue_columns(@parent, closed_on: Time.utc(2026, 1, 30, 3)) # the issue itself is not its child

    assert_equal @child2, @fetcher.issue_child(@parent.reload)
  end

  def test_issue_child_is_nil_for_an_issue_without_children
    assert_nil @fetcher.issue_child(@child1.reload)
  end

  def test_issue_journal_is_the_done_ratio_changes_until_the_end_of_the_basis_date_oldest_first
    first = Journal.where(journalized_id: @issue1.id).order(:id).last # 50% on 2026-01-07
    note = create_journal(@issue1, Time.utc(2026, 1, 7, 2), notes: "only a note")
    second = create_journal(@issue1, Time.utc(2026, 1, 9, 3), done_ratio: %w[50 80])

    assert_equal [first.id, second.id], @fetcher.issue_journal(@issue1, Date.new(2026, 1, 10)).map(&:id)
    assert_equal [first.id], @fetcher.issue_journal(@issue1, Date.new(2026, 1, 8)).map(&:id)
    assert_empty @fetcher.issue_journal(@issue1, Date.new(2026, 1, 6))
    assert_not_includes @fetcher.issue_journal(@issue1, Date.new(2026, 1, 10)).map(&:id), note.id
  end

  # ---- difference from a baseline --------------------------------------------

  def test_diff_new_issues_are_the_issues_that_are_not_in_the_baseline
    actual = { @issue1.id => { x: 1 }, @issue2.id => { x: 2 }, @dated.id => { x: 3 } }
    baseline = { @issue1.id => { x: 1 } }

    assert_equal ids(:issue2, :dated), sorted_ids(@fetcher.diff_new_issues(actual, baseline))
  end

  def test_diff_modify_issues_are_the_issues_in_both_with_other_values
    actual = { @issue1.id => { x: 1 }, @issue2.id => { x: 2 }, @dated.id => { x: 3 } }
    baseline = { @issue1.id => { x: 1 }, @issue2.id => { x: 9 }, @sub.id => { x: 4 } }

    assert_equal ids(:issue2), sorted_ids(@fetcher.diff_modify_issues(actual, baseline))
  end

  def test_diff_remove_issues_are_the_issues_only_in_the_baseline_in_the_baseline_order
    actual = { @issue1.id => { x: 1 } }
    baseline = { @sub.id => { x: 1 }, @issue1.id => { x: 1 }, @issue2.id => { x: 2 }, 0 => { x: 3 } }

    assert_equal [@sub.id, @issue2.id], @fetcher.diff_remove_issues(actual, baseline).map(&:id)
  end
end
