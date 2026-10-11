require File.expand_path("evm_calculation_test_helper", __dir__)
require "minitest/mock"

# Unit tests for ProjectEvmBuilder#build_project_evm (lib/project_evm_builder.rb),
# the one place EvmsController and EvmHookViewListner now build the project-level
# CalculateEvm.
#
# build_project_evm calls #evm_issues / #evm_costs on self (they come from
# IssueDataFetcher in the plugin and hit the database), so the host class
# below defines them as recording stubs instead. What is pinned down here is
# the wiring: which collaborators get called with which arguments, and that
# the result is a CalculateEvmLogic::CalculateEvm built from exactly what they
# returned. The baseline lookup (BaselineDataFetcher.project_baseline, which
# queries Evmbaseline through ActiveRecord) is stubbed too, so the SQL behind it
# is not exercised here -- only that its result is used as the baseline.
class ProjectEvmBuilderTest < ActiveSupport::TestCase
  # Host that mixes in ProjectEvmBuilder, standing in for EvmsController /
  # EvmHookViewListner.
  class Host
    include ProjectEvmBuilder

    attr_reader :calls

    def initialize(issues, costs)
      @issues = issues
      @costs = costs
      @calls = []
    end

    def evm_issues(project)
      @calls << [:evm_issues, project]
      @issues
    end

    def evm_costs(project)
      @calls << [:evm_costs, project]
      @costs
    end
  end

  def setup
    @issue = FakeIssue.new(Date.new(2026, 1, 1), Date.new(2026, 1, 5), 10.0, 40, nil, false,
                           [FakeJournal.new(Time.utc(2026, 1, 2, 1, 0, 0), 40)])
    @costs = { Date.new(2026, 1, 2) => 6.0, Date.new(2026, 1, 3) => 2.0 }
    @project = Object.new
    @cfg_param = { basis_date: Date.new(2026, 1, 3), working_hours: 8, forecast: true,
                   etc_method: "method2", exclude_holiday: false, region: nil,
                   baseline_id: nil }
  end

  def test_builds_a_calculate_evm_from_the_projects_issues_and_costs
    host = Host.new([@issue], @costs)

    evm = host.build_project_evm(@project, @cfg_param)

    assert_instance_of CalculateEvmLogic::CalculateEvm, evm
    assert_equal 10.0, evm.bac
    assert_equal 4.0, evm.today_ev
    assert_equal 8.0, evm.today_ac
  end

  def test_fetches_issues_and_costs_for_the_given_project_in_that_order
    host = Host.new([@issue], @costs)

    host.build_project_evm(@project, @cfg_param)

    assert_equal [[:evm_issues, @project], [:evm_costs, @project]], host.calls
    assert_same @project, host.calls.first.last
  end

  def test_uses_the_actual_plan_when_no_baseline_is_selected
    host = Host.new([@issue], @costs)

    evm = host.build_project_evm(@project, @cfg_param)

    assert_nil evm.pv_baseline
    assert_same evm.pv_actual, evm.pv
  end

  def test_an_empty_baseline_id_is_treated_as_no_baseline
    host = Host.new([@issue], @costs)

    evm = host.build_project_evm(@project, @cfg_param.merge(baseline_id: ""))

    assert_nil evm.pv_baseline
  end

  def test_looks_the_baseline_up_by_id_and_uses_it_for_pv
    host = Host.new([@issue], @costs)
    baseline_issues = [FakeIssue.new(Date.new(2026, 1, 1), Date.new(2026, 1, 10), 20.0)]
    requested_id = nil
    finder = lambda do |baseline_id|
      requested_id = baseline_id
      baseline_issues
    end

    evm = BaselineDataFetcher.stub(:project_baseline, finder) do
      host.build_project_evm(@project, @cfg_param.merge(baseline_id: 5))
    end

    assert_equal 5, requested_id
    assert_not_nil evm.pv_baseline
    assert_same evm.pv_baseline, evm.pv
    assert_equal 20.0, evm.bac             # the baseline's BAC
    assert_equal 10.0, evm.pv_actual.bac   # the actual plan is still available
  end

  def test_forwards_the_calculation_options_to_calculate_evm
    host = Host.new([@issue], @costs)

    evm = host.build_project_evm(@project, @cfg_param.merge(etc_method: "method1", forecast: false))

    assert_equal Date.new(2026, 1, 3), evm.basis_date
    assert_equal false, evm.forecast
    # method1 divides the remaining work (10 - 4 = 6h) by 1.0
    assert_equal 6.0, evm.etc
  end

  def test_builds_an_evm_for_a_project_with_no_issues
    host = Host.new([], {})

    evm = host.build_project_evm(@project, @cfg_param)

    assert_equal 0.0, evm.bac
    assert_equal [:no_work, :within_duration], evm.project_state
  end
end
