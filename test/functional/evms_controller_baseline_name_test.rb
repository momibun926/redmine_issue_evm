require File.expand_path("evm_functional_test_helper", __dir__)

# The name of the baseline in use is shown in the tabs of the main EVM page that hold
# values of the baseline plan (EVM, ES and the EVM chart), "none" when no baseline is used.
class EvmsControllerBaselineNameTest < Redmine::ControllerTest
  # The tabs of the page, in order: the n-th "div" of the tab wrap
  TABS = { evm: 1, es: 2, chart: 3 }.freeze

  tests EvmsController
  include EvmFunctionalTestSupport

  def setup
    sign_in_as_project_member
    create_evm_setting
    @plans = [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 40.0]]
  end

  def test_the_name_of_the_selected_baseline_is_shown_in_every_tab
    old = create_baseline("old plan", Time.utc(2026, 1, 1), @plans)
    create_baseline("latest plan", Time.utc(2026, 1, 3), @plans)

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", evmbaseline_id: old.id }

    assert_baseline_name_in_every_tab "old plan"
  end

  def test_the_latest_baseline_is_shown_when_none_is_selected
    create_baseline("old plan", Time.utc(2026, 1, 1), @plans)
    create_baseline("latest plan", Time.utc(2026, 1, 3), @plans)

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    assert_baseline_name_in_every_tab "latest plan"
  end

  def test_none_is_shown_when_the_project_has_no_baseline
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    assert_baseline_name_in_every_tab I18n.t(:label_baseline_none)
  end

  def test_none_is_shown_when_the_baseline_is_not_used
    create_baseline("latest plan", Time.utc(2026, 1, 3), @plans)

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", no_use_baseline: "1" }

    assert_baseline_name_in_every_tab I18n.t(:label_baseline_none)
  end

  def test_the_name_is_shown_in_the_language_of_the_user
    User.find(2).update!(language: "ja")

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    assert_select "div.tab-wrap > div:nth-of-type(1) .used-baseline", text: "ベースライン名 : なし"
  end

  private

  def assert_baseline_name_in_every_tab(name)
    TABS.each_value do |position|
      assert_select "div.tab-wrap > div:nth-of-type(#{position}) .used-baseline",
                    text: "#{I18n.t(:label_baseline)} : #{name}"
    end
  end
end
