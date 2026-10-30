require File.expand_path("../../test_helper", __dir__)

# Unit test for BaselineDataFetcher (lib/baseline_data_fetcher.rb).
#
# BaselineDataFetcher used to be `include`d into BaseevmController /
# EvmHookViewListner like the other lib/ modules; it is now called
# explicitly as BaselineDataFetcher.project_baseline(...) /
# .selectable_baseline_list(...) (see ProjectEvmBuilder#build_project_evm
# and the current-state analysis doc, section 12).
#
# #selectable_baseline_list issues a real ActiveRecord query and needs a
# database, so it isn't covered here (no DB is available in this test
# environment -- see the other lib/ unit tests' comments for the same
# constraint). #project_baseline's blank-id guard clause needs no DB at
# all, so it's covered directly.
class BaselineDataFetcherTest < ActiveSupport::TestCase
  def test_project_baseline_returns_nil_without_querying_when_baseline_id_is_blank
    assert_nil BaselineDataFetcher.project_baseline(nil)
    assert_nil BaselineDataFetcher.project_baseline("")
  end

  def test_module_function_keeps_these_methods_private_if_ever_mixed_in
    host_class = Class.new { include BaselineDataFetcher }

    assert_raises(NoMethodError) { host_class.new.project_baseline(nil) }
  end
end
