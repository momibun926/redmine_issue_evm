require File.expand_path("issue_data_fetcher_scenario", __dir__)

# The EV and PV calculations read the database a fixed number of times,
# not once for each issue. See IssueDataFetcherScenario for the data.
class CalculateEvmQueriesTest < ActiveSupport::TestCase
  include IssueDataFetcherScenario

  # The EV calculation of the plugin before the journals and statuses were
  # read in one query: one query for each issue.
  class OneQueryPerIssueEv < CalculateEv
    private

    def ev_journals_by_issue(_issues, _basis_date)
      {}
    end

    def journals_of(issue, basis_date)
      issue_journal(issue, basis_date)
    end
  end

  BASIS_DATE = Date.new(2026, 1, 31)

  def setup
    super
    create_journal(@issue1, Time.utc(2026, 1, 9, 3), done_ratio: %w[50 80])
    create_journal(@issue2, Time.utc(2026, 1, 13, 3), done_ratio: %w[0 40])
    update_issue_columns(@child1, status_id: 5, closed_on: Time.utc(2026, 1, 20, 3))
  end

  def test_ev_is_the_same_as_reading_the_journals_of_each_issue
    expected = OneQueryPerIssueEv.new(BASIS_DATE, issues)

    actual = CalculateEv.new(BASIS_DATE, issues)

    assert_equal expected.cumulative, actual.cumulative
    assert_equal expected.state, actual.state
  end

  def test_ev_queries_do_not_grow_with_the_issues
    before = ev_query_count
    3.times do |i|
      issue = create_scenario_issue(@project, "more #{i}", [Date.new(2026, 1, 5), Date.new(2026, 1, 9)], 4)
      create_journal(issue, Time.utc(2026, 1, 7, 3), done_ratio: %w[0 50])
      update_issue_columns(issue, status_id: 5, closed_on: Time.utc(2026, 1, 9, 3))
    end

    assert_equal before, ev_query_count
  end

  def test_pv_looks_up_each_version_once
    version = Version.create!(project: @project, name: "Shared", effective_date: Date.new(2026, 2, 27))
    undated = Array.new(3) do
      Issue.new(start_date: Date.new(2026, 2, 23), due_date: nil, fixed_version_id: version.id, estimated_hours: 5)
    end

    pv = assert_queries_count(1) { CalculatePv.new(BASIS_DATE, undated, "jp", true) }

    assert_equal Date.new(2026, 2, 27), pv.due_date
    assert_in_delta 15.0, pv.bac
  end

  private

  def issues
    @fetcher.evm_issues(@project).to_a
  end

  def ev_query_count
    loaded = issues
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { CalculateEv.new(BASIS_DATE, loaded) }
    count
  end
end
