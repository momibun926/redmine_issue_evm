require File.expand_path("../../test_helper", __dir__)

# Minimal stand-in for an Evmsetting record, exposing only the attributes
# EvmSettingParamBuilder#cfg_param_from_setting reads.
FakeEvmSetting = Struct.new(:view_performance, :view_issuelist, :view_forecast,
                            :threshold_spi, :threshold_cpi, :threshold_cr,
                            :etc_method, :basis_hours, :exclude_holidays, :region)

# Unit tests for EvmSettingParamBuilder (lib/evm_setting_param_builder.rb), the
# module both BaseevmController#find_common_setting and
# EvmHookViewListner#view_projects_show_left use to turn an Evmsetting record
# into the cfg_param hash CalculateEvm and the views read.
#
# Two behaviors this test exists specifically to pin down (see the current-state
# analysis doc, section 10):
#
# 1. The hash is keyed :etc_method, matching what CalculateEvm#initialize reads
#    (options[:etc_method]) -- not :calcetc, the key BaseevmController used to
#    write it under, which CalculateEvm never read back. Selecting method1 or
#    method3 in the EVM settings silently had no effect until this was fixed.
# 2. Every key CalculateEvm#initialize accepts is present, so a caller that
#    forgets one (as EvmHookViewListner used to forget all but basis_date and
#    baseline_id) can't happen again -- the hook's sidebar widget could
#    otherwise show different PV/SV than the main EVM page for any project
#    using exclude_holiday or region.
class EvmSettingParamBuilderTest < ActiveSupport::TestCase
  include EvmSettingParamBuilder

  def setup
    @setting = FakeEvmSetting.new(true, false, true, 0.9, 0.8, 0.7,
                                  "method3", 8.0, true, "jp")
  end

  def test_maps_every_calculate_evm_option
    cfg_param = cfg_param_from_setting(@setting)

    assert_equal "method3", cfg_param[:etc_method]
    assert_equal true, cfg_param[:forecast]
    assert_equal 8.0, cfg_param[:working_hours]
    assert_equal true, cfg_param[:exclude_holiday]
    assert_equal "jp", cfg_param[:region]
  end

  def test_maps_the_display_only_options_the_views_read
    cfg_param = cfg_param_from_setting(@setting)

    assert_equal true, cfg_param[:display_performance]
    assert_equal false, cfg_param[:display_incomplete]
    assert_equal 0.9, cfg_param[:limit_spi]
    assert_equal 0.8, cfg_param[:limit_cpi]
    assert_equal 0.7, cfg_param[:limit_cr]
  end

  def test_does_not_use_the_old_dead_calcetc_key
    cfg_param = cfg_param_from_setting(@setting)

    assert_not cfg_param.key?(:calcetc)
  end
end
