require File.expand_path("evm_calculation_test_helper", __dir__)
require "minitest/mock"

# Unit tests for EvmHookViewListner#view_projects_show_left
# (lib/evm_hook_view_listner.rb), the hook that renders the EVM widget on the
# project overview page.
#
# The database-backed collaborators are stubbed:
# - Evmsetting.find_by         -> a plain Struct (the project's EVM setting)
# - BaselineDataFetcher.selectable_baseline_list -> an Array of plain Structs
# - #build_project_evm         -> records what it was called with
# - the controller             -> records the partial and locals it was asked to render
# so what is tested is the hook's own logic: which cases render an EVM at
# all, how the cfg_param is assembled, and what is handed to the partial.
# (ProjectEvmBuilder and EvmSettingParamBuilder have their own tests.)
class EvmHookViewListnerTest < ActiveSupport::TestCase
  HookFakeSetting = Struct.new(:view_performance, :view_issuelist, :view_forecast,
                               :threshold_spi, :threshold_cpi, :threshold_cr,
                               :etc_method, :basis_hours, :exclude_holidays, :region)
  HookFakeProject = Struct.new(:id)
  HookFakeBaseline = Struct.new(:id, :subject)

  # Records the render call the hook makes via context[:controller].send(...)
  class HookFakeController
    attr_reader :rendered

    def render_to_string(options)
      @rendered = options
      "rendered"
    end
  end

  def setup
    @listener = EvmHookViewListner.instance
    @controller = HookFakeController.new
    @project = HookFakeProject.new(7)
    @context = { project: @project, controller: @controller }
    @setting = HookFakeSetting.new(true, false, true, 0.9, 0.8, 0.7, "method3", 8.0, true, "jp")
    @build_calls = []
    @build_stub = lambda do |project, cfg_param|
      @build_calls << [project, cfg_param.dup]
      :project_evm
    end
  end

  def test_without_an_evm_setting_it_renders_the_partial_with_nothing_and_builds_no_evm
    result = Evmsetting.stub(:find_by, nil) do
      @listener.stub(:build_project_evm, @build_stub) do
        @listener.view_projects_show_left(@context)
      end
    end

    assert_equal "rendered", result
    assert_empty @build_calls
    assert_equal "hooks/view_projects_show_left", @controller.rendered[:partial]
    assert_equal({ evm: nil, working_hours: nil, baseline_subject: nil }, @controller.rendered[:locals])
  end

  def test_looks_the_setting_up_by_the_projects_id
    received = nil
    finder = lambda do |conditions|
      received = conditions
      nil
    end

    Evmsetting.stub(:find_by, finder) do
      @listener.view_projects_show_left(@context)
    end

    assert_equal({ project_id: 7 }, received)
  end

  def test_with_a_setting_and_no_baseline_it_builds_the_evm_from_the_setting
    render_with(@setting, [])

    assert_equal 1, @build_calls.length
    project, cfg_param = @build_calls.first
    assert_same @project, project
    # the settings-derived keys (EvmSettingParamBuilder) ...
    assert_equal "method3", cfg_param[:etc_method]
    assert_equal true, cfg_param[:exclude_holiday]
    assert_equal "jp", cfg_param[:region]
    assert_equal 8.0, cfg_param[:working_hours]
    # ... plus the basis date, and no baseline_id since there is no baseline
    assert_kind_of Date, cfg_param[:basis_date]
    assert_not cfg_param.key?(:baseline_id)
    assert_equal({ evm: :project_evm, working_hours: 8.0, baseline_subject: nil }, @controller.rendered[:locals])
  end

  def test_with_baselines_it_uses_the_first_one_and_shows_its_subject
    latest = HookFakeBaseline.new(31, "latest baseline")
    older = HookFakeBaseline.new(12, "older baseline")

    render_with(@setting, [latest, older])

    _project, cfg_param = @build_calls.first
    assert_equal 31, cfg_param[:baseline_id]
    assert_equal "latest baseline", @controller.rendered[:locals][:baseline_subject]
  end

  private

  # Runs the hook with the setting / baseline list stubbed in
  def render_with(setting, baselines)
    Evmsetting.stub(:find_by, setting) do
      BaselineDataFetcher.stub(:selectable_baseline_list, baselines) do
        @listener.stub(:build_project_evm, @build_stub) do
          @listener.view_projects_show_left(@context)
        end
      end
    end
  end
end
