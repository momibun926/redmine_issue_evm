require File.expand_path("evm_functional_test_helper", __dir__)

# Contract shared by the four "EVM by assignee / version / tracker / parent
# issue" pages, which are all EvmBreakdownController#index. A test class
# including it defines:
#   selected_param      the request parameter holding the selected ids
#   selectable_ids      ids the page offers (in the scenario project)
#   selectable_option_ids  ids found in the page's selectable list
#   selected_values     ids sent in the request: [one id, another id]
#   description_of(id)  what the page shows as the EVM description
module EvmBreakdownContract
  def self.included(base)
    base.include EvmFunctionalTestSupport
  end

  def setup
    sign_in_as_project_member
    create_evm_setting
    prepare_scenario
  end

  def test_without_a_selection_it_only_lists_the_selectable_options
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    assert_response :success
    assert_equal({}, controller_ivar(:evm_data))
    assert_equal({}, controller_ivar(:evm_chart_data))
    assert_equal selectable_ids.sort, selectable_option_ids.sort
  end

  def test_one_selected_id_gets_its_own_evm_and_chart
    first, = selected_values

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", selected_param => [first] }

    assert_response :success
    assert_equal [first.to_s], controller_ivar(:evm_data).keys
    assert_equal [first.to_s], controller_ivar(:evm_chart_data).keys
    evm = controller_ivar(:evm_data)[first.to_s]
    assert_equal description_of(first), evm.description.to_s
    assert_equal Date.new(2026, 1, 8), evm.basis_date
    assert_equal ChartDataMaker.evm_chart_data(evm), controller_ivar(:evm_chart_data)[first.to_s]
  end

  def test_without_a_basis_date_the_evm_is_calculated_for_today
    first, = selected_values

    travel_to Time.utc(2026, 1, 8, 12, 0, 0) do
      get :index, params: { project_id: @project.id, selected_param => [first] }
    end

    assert_response :success
    assert_equal Date.new(2026, 1, 8), controller_ivar(:evm_data)[first.to_s].basis_date
    assert_equal Date.new(2026, 1, 8), controller_ivar(:cfg_param)[:basis_date]
  end

  def test_a_blank_basis_date_is_treated_as_today
    first, = selected_values

    travel_to Time.utc(2026, 1, 8, 12, 0, 0) do
      get :index, params: { project_id: @project.id, basis_date: "", selected_param => [first] }
    end

    assert_response :success
    assert_equal Date.new(2026, 1, 8), controller_ivar(:evm_data)[first.to_s].basis_date
  end

  def test_several_selected_ids_get_one_evm_each_in_the_order_selected
    first, second = selected_values

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", selected_param => [second, first] }

    assert_equal [second.to_s, first.to_s], controller_ivar(:evm_data).keys
    assert_equal [second.to_s, first.to_s], controller_ivar(:evm_chart_data).keys
  end

  def test_the_options_of_the_main_page_are_passed_on
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", no_use_baseline: "1",
                          display_explanation: "1" }

    cfg_param = controller_ivar(:cfg_param)
    assert_equal %w[2026-01-08 1 1],
                 [cfg_param[:basis_date], cfg_param[:no_use_baseline], cfg_param[:display_explanation]]
  end

  def test_a_user_who_is_not_a_member_is_denied
    @request.session[:user_id] = 3

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    assert_response :forbidden
  end

  def test_a_member_without_the_view_permission_is_denied
    Role.find(1).remove_permission!(:view_evms)

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    assert_response :forbidden
  end

  private

  def prepare_scenario; end
end

class EvmassigneesControllerTest < Redmine::ControllerTest
  include EvmBreakdownContract

  def prepare_scenario
    update_issue_columns(@issue2, assigned_to_id: 3)
  end

  def selected_param
    :selected_assignee_id
  end

  def selectable_ids
    [2, 3]
  end

  def selectable_option_ids
    controller_ivar(:selectable_options).values
  end

  def selected_values
    [2, 3]
  end

  def description_of(id)
    User.find(id).to_s
  end

  def test_an_issue_without_an_assignee_is_selected_with_a_blank_id
    update_issue_columns(@issue2, assigned_to_id: nil)

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", selected_assignee_id: [""] }

    assert_response :success
    assert_equal [""], controller_ivar(:evm_data).keys
    assert_equal I18n.t(:no_assignee), controller_ivar(:evm_data)[""].description.to_s
    assert_equal 20.0, controller_ivar(:evm_data)[""].bac
  end

  def test_each_assignee_gets_the_evm_of_their_own_issues
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", selected_assignee_id: %w[2 3] }

    assert_equal [40.0, 20.0], [controller_ivar(:evm_data)["2"].bac, controller_ivar(:evm_data)["3"].bac]
  end
end

class EvmversionsControllerTest < Redmine::ControllerTest
  include EvmBreakdownContract

  def prepare_scenario
    @version2 = Version.create!(project: @project, name: "Release 2", effective_date: Date.new(2026, 1, 30))
    update_issue_columns(@issue2, fixed_version_id: @version2.id)
  end

  def selected_param
    :selected_version_id
  end

  def selectable_ids
    [@issue1.fixed_version_id, @version2.id]
  end

  def selectable_option_ids
    controller_ivar(:selectable_options).map(&:fixed_version_id)
  end

  def selected_values
    [@issue1.fixed_version_id, @version2.id]
  end

  def description_of(id)
    "#{@project.name} #{Version.find(id).name}"
  end

  def test_each_version_gets_the_evm_of_its_own_issues
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08",
                          selected_version_id: [@issue1.fixed_version_id, @version2.id] }

    assert_equal [40.0, 20.0], controller_ivar(:evm_data).values.map(&:bac)
  end
end

class EvmtrackersControllerTest < Redmine::ControllerTest
  include EvmBreakdownContract

  def selected_param
    :selected_tracker_id
  end

  def selectable_ids
    [1, 2]
  end

  def selectable_option_ids
    controller_ivar(:selectable_options).map(&:tracker_id)
  end

  def selected_values
    [1, 2]
  end

  def description_of(id)
    Tracker.find(id).name
  end

  def test_each_tracker_gets_the_evm_of_its_own_issues
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", selected_tracker_id: %w[1 2] }

    assert_equal [40.0, 20.0], controller_ivar(:evm_data).values.map(&:bac)
  end
end

class EvmparentissuesControllerTest < Redmine::ControllerTest
  include EvmBreakdownContract

  def prepare_scenario
    @parent1 = create_scenario_issue(@project, "Parent 1", [Date.new(2026, 1, 5), Date.new(2026, 1, 9)], nil)
    @parent2 = create_scenario_issue(@project, "Parent 2", [Date.new(2026, 1, 12), Date.new(2026, 1, 16)], nil)
    @issue1.reload.update!(parent_issue_id: @parent1.id)
    @issue2.reload.update!(parent_issue_id: @parent2.id)
  end

  def selected_param
    :selected_parent_issue_id
  end

  def selectable_ids
    [@parent1.id, @parent2.id]
  end

  def selectable_option_ids
    controller_ivar(:selectable_options).map(&:id)
  end

  def selected_values
    [@parent1.id, @parent2.id]
  end

  def description_of(id)
    Issue.find(id).subject
  end

  def test_each_parent_gets_the_evm_of_its_descendants
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08",
                          selected_parent_issue_id: [@parent1.id, @parent2.id] }

    assert_equal [@parent1.id.to_s, @parent2.id.to_s], controller_ivar(:evm_data).keys
    assert_equal([40.0, 20.0], controller_ivar(:evm_data).values.map(&:bac))
  end
end
