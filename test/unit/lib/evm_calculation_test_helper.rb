# Shared test support for unit-testing the EVM calculation core
# (BaseCalculateEvm / CalculateAc / CalculatePv / CalculateEv / CalculateEvm).
#
# CalculateEv reaches into IssueDataFetcher#issue_journal and #issue_child to load
# Journal records and a child Issue from the database (see lib/calculate_ev.rb and
# lib/issue_data_fetcher.rb). That collaboration is exactly what a *unit* test for the
# calculation logic should not depend on: pulling in real Journal/Issue fixtures would
# turn every EV test into a full integration test.
#
# So this file overrides those two methods directly on CalculateEv to read from plain
# Ruby doubles (FakeIssue/FakeJournal below) instead of the database. This is a test
# seam only: it is loaded from test files, never from the plugin itself, so runtime
# behavior in the actual application (a real Redmine request) is unchanged.
require File.expand_path("../../test_helper", __dir__)

# Minimal stand-in for a Redmine Journal, exposing only what
# CalculateEv#daily_done_ratio actually reads: created_on and
# details.first.value (the new done_ratio value of that journal entry).
FakeJournal = Struct.new(:created_on, :ratio) do
  def details
    [Struct.new(:value).new(ratio.to_s)]
  end
end

# Minimal stand-in for a Redmine Issue, exposing only what
# CalculatePv#calculate_planed_value and CalculateEv#calculate_earned_value
# actually read.
#
# - journal_entries: array of FakeJournal, returned by the CalculateEv#issue_journal
#   test seam below.
# - child_issue: a single FakeIssue, returned by the CalculateEv#issue_child test seam
#   below (mirrors IssueDataFetcher#issue_child, which returns one child issue).
FakeIssue = Struct.new(:start_date, :due_date, :estimated_hours, :done_ratio,
                       :closed_on, :has_children, :journal_entries, :child_issue) do
  def closed?
    !closed_on.nil?
  end

  def children?
    !!has_children
  end
end

class CalculateEv
  # Test seam: replaces the DB-backed IssueDataFetcher#issue_journal for
  # FakeIssue objects. Real issues still go through IssueDataFetcher, so
  # loading this file does not change other tests that run in the same
  # process (e.g. under `rake redmine:plugins:test`). See file comment above.
  def issue_journal(issue, basis_date)
    return super unless issue.is_a?(FakeIssue)

    issue.journal_entries || []
  end

  # Test seam: replaces the DB-backed IssueDataFetcher#issue_child for
  # FakeIssue objects. See file comment above.
  def issue_child(issue)
    return super unless issue.is_a?(FakeIssue)

    issue.child_issue
  end
end

# Temporarily replaces a method of an object (class method, or a method of one
# instance) for the duration of a block.
#
# Minitest 6 no longer ships "minitest/mock" (it moved to the separate
# minitest-mock gem), so this keeps the tests independent of the Minitest
# version. It behaves like Minitest::Mock's #stub: a value is returned as it
# is, a callable (lambda) is called with the arguments of the stubbed call.
module EvmTestStubs
  # @param [Object] target class, module or instance whose method is replaced
  # @param [Symbol] name method name
  # @param [Object] value_or_callable return value, or a callable that receives the call's arguments
  # @return the value of the block
  def stub_method(target, name, value_or_callable)
    singleton = target.singleton_class
    original = singleton.instance_method(name) if own_singleton_method?(singleton, name)
    singleton.send(:define_method, name) do |*args, **kwargs, &blk|
      next value_or_callable unless value_or_callable.respond_to?(:call)

      kwargs.empty? ? value_or_callable.call(*args, &blk) : value_or_callable.call(*args, **kwargs, &blk)
    end
    yield
  ensure
    original ? singleton.send(:define_method, name, original) : singleton.send(:remove_method, name)
  end

  private

  def own_singleton_method?(singleton, name)
    singleton.instance_methods(false).include?(name) || singleton.private_instance_methods(false).include?(name)
  end
end

ActiveSupport::TestCase.include(EvmTestStubs)
