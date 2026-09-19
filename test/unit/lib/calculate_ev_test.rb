require File.expand_path("evm_calculation_test_helper", __dir__)

# Unit tests for CalculateEv (Earned Value).
#
# calculate_earned_value (lib/calculate_ev.rb) branches on three cases per issue:
#   1. closed issue        -> EV built from its done_ratio journal history, capped at
#                              100% on the close date
#   2. open issue with a   -> EV built from its done_ratio journal history
#      positive done_ratio
#   3. open parent issue   -> only looked at when its own done_ratio is NOT positive
#      whose child closed     (see the elsif chain), and credits the closed child's
#                              own estimated_hours (in full) on the child's close
#                              date -- a parent's EV is the sum of its children's
#                              EV, not a share of the parent's own estimated_hours.
#
# See evm_calculation_test_helper.rb for FakeIssue/FakeJournal and for why
# issue_journal/issue_child are stubbed instead of hitting the database.
class CalculateEvTest < ActiveSupport::TestCase
  def test_closed_issue_builds_ev_from_its_journal_history_and_the_close_date
    # done_ratio journal: 0% -> 60% on Jan 2, then closed (=100%) on Jan 4
    issue = FakeIssue.new(nil, nil, 10.0, 100,
                          Time.utc(2026, 1, 4, 3, 0, 0), false,
                          [FakeJournal.new(Time.utc(2026, 1, 2, 1, 0, 0), 60)])

    ev = CalculateEv.new(Date.new(2026, 1, 10), [issue])

    assert_equal 6.0, ev.daily[Date.new(2026, 1, 2)]
    assert_equal 4.0, ev.daily[Date.new(2026, 1, 4)]
    assert_equal 10.0, ev.today_value
    assert_equal Date.new(2026, 1, 2), ev.min_date
    assert_equal Date.new(2026, 1, 4), ev.max_date
  end

  def test_open_issue_with_a_positive_done_ratio_builds_ev_from_its_journal_history
    issue = FakeIssue.new(nil, nil, 8.0, 40, nil, false,
                          [FakeJournal.new(Time.utc(2026, 1, 3, 0, 0, 0), 40)])

    ev = CalculateEv.new(Date.new(2026, 1, 10), [issue])

    assert_equal 3.2, ev.daily[Date.new(2026, 1, 3)]
    assert_equal 3.2, ev.today_value
  end

  def test_multiple_journal_entries_only_add_the_incremental_ratio_change
    # 0% -> 20% (Jan2) -> 70% (Jan4) -> closed/100% (Jan6)
    issue = FakeIssue.new(nil, nil, 10.0, 100, Time.utc(2026, 1, 6, 0, 0, 0), false,
                          [FakeJournal.new(Time.utc(2026, 1, 2, 0, 0, 0), 20),
                           FakeJournal.new(Time.utc(2026, 1, 4, 0, 0, 0), 70)])

    ev = CalculateEv.new(Date.new(2026, 1, 10), [issue])

    assert_equal 2.0, ev.daily[Date.new(2026, 1, 2)]
    assert_equal 5.0, ev.daily[Date.new(2026, 1, 4)]
    assert_equal 3.0, ev.daily[Date.new(2026, 1, 6)]
    assert_equal 10.0, ev.today_value
  end

  def test_parent_issue_with_a_closed_child_credits_the_child_own_estimated_hours
    # Reachable only when the parent's own done_ratio is 0 (see the elsif chain in
    # calculate_earned_value). Fixed 2026-09-19 (see the current-state analysis doc,
    # section 8/14): this branch used to add
    # issue.estimated_hours * issue.done_ratio / 100, but issue.done_ratio is
    # guaranteed 0 to even reach this branch, so it always contributed 0.0 EV no
    # matter what the child did. A parent's EV is the sum of its children's EV, so
    # the fix credits the closed child's own estimated_hours in full (child closed
    # == 100%, same convention the issue.closed? branch above already uses) on the
    # child's close date, instead of a (always-zero) share of the parent's own
    # estimated_hours.
    child = FakeIssue.new(nil, nil, 5.0, 100, Time.utc(2026, 1, 6, 0, 0, 0), false)
    parent = FakeIssue.new(nil, nil, 12.0, 0, nil, true, nil, child)

    ev = CalculateEv.new(Date.new(2026, 1, 10), [parent])

    assert ev.daily.key?(Date.new(2026, 1, 6))
    assert_equal 5.0, ev.daily[Date.new(2026, 1, 6)]
  end

  def test_parent_issue_with_a_closed_child_that_has_no_estimated_hours_still_adds_nothing
    # Not a regression: if the child itself has no estimated_hours, there is
    # nothing to credit, same as any other 0-estimated-hours issue in this class.
    child = FakeIssue.new(nil, nil, 0.0, 100, Time.utc(2026, 1, 6, 0, 0, 0), false)
    parent = FakeIssue.new(nil, nil, 12.0, 0, nil, true, nil, child)

    ev = CalculateEv.new(Date.new(2026, 1, 10), [parent])

    assert_equal 0.0, ev.daily[Date.new(2026, 1, 6)]
  end

  def test_state_is_no_work_when_there_are_no_issues
    ev = CalculateEv.new(Date.new(2026, 1, 10), [])

    assert_equal :no_work, ev.state(nil)
  end

  def test_state_is_progress_for_an_issue_still_short_of_full_progress
    issue = FakeIssue.new(nil, nil, 8.0, 40, nil, false,
                          [FakeJournal.new(Time.utc(2026, 1, 3, 0, 0, 0), 40)])

    ev = CalculateEv.new(Date.new(2026, 1, 10), [issue])

    assert_equal :progress, ev.state(nil)
  end

  def test_state_is_finished_when_every_issue_is_closed
    issue = FakeIssue.new(nil, nil, 10.0, 100, Time.utc(2026, 1, 4, 3, 0, 0), false,
                          [FakeJournal.new(Time.utc(2026, 1, 2, 1, 0, 0), 60)])

    ev = CalculateEv.new(Date.new(2026, 1, 10), [issue])

    assert_equal :finished, ev.state(nil)
  end
end
