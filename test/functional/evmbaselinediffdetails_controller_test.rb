require File.expand_path("evm_functional_test_helper", __dir__)

# Functional tests of EvmbaselinediffdetailsController#index: how the current
# plan differs from a baseline.
class EvmbaselinediffdetailsControllerTest < Redmine::ControllerTest
  include EvmFunctionalTestSupport

  def setup
    sign_in_as_project_member
    create_evm_setting
    @removed = create_scenario_issue(@project, "Removed later", [Date.new(2026, 1, 5), Date.new(2026, 1, 6)], 4)
    # In the baseline: issue 1 with other dates, issue "removed" as it is now, no issue 2.
    @baseline = create_baseline("baseline", Time.utc(2026, 1, 1),
                                [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 12), 40.0],
                                 [@removed, Date.new(2026, 1, 5), Date.new(2026, 1, 6), 4.0]])
    # The plan no longer includes it: its dates were cleared.
    update_issue_columns(@removed, start_date: nil, due_date: nil)
  end

  def test_index_lists_modified_new_and_removed_issues
    get :index, params: { project_id: @project.id, baseline_id: @baseline.id }

    assert_response :success
    assert_equal [@issue1.id], controller_ivar(:modify_issues).map(&:id)
    assert_equal [@issue2.id], controller_ivar(:new_issues).map(&:id)
    assert_equal [@removed.id], controller_ivar(:remove_issues).map(&:id)
    assert_equal [@issue1.id, @removed.id].sort, controller_ivar(:baseline_issue).keys.sort
    assert_equal({ start_date: Date.new(2026, 1, 5), due_date: Date.new(2026, 1, 12), estimated_hours: 40.0 },
                 controller_ivar(:baseline_issue)[@issue1.id])
    assert_equal @baseline.id.to_s, controller_ivar(:cfg_param)[:baseline_id]
  end

  def test_an_issue_that_is_the_same_as_in_the_baseline_is_not_listed
    other = create_baseline("same", Time.utc(2026, 1, 2),
                            [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 40.0],
                             [@issue2, Date.new(2026, 1, 12), Date.new(2026, 1, 16), 20.0]])

    get :index, params: { project_id: @project.id, baseline_id: other.id }

    assert_empty controller_ivar(:modify_issues)
    assert_empty controller_ivar(:new_issues)
    assert_empty controller_ivar(:remove_issues)
  end

  def test_a_baseline_issue_that_was_deleted_is_left_out_of_the_removed_issues
    deleted = create_scenario_issue(@project, "Deleted later", [Date.new(2026, 1, 5), Date.new(2026, 1, 6)], 4)
    baseline = create_baseline("with deleted", Time.utc(2026, 1, 2),
                               [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 40.0],
                                [deleted, Date.new(2026, 1, 5), Date.new(2026, 1, 6), 4.0],
                                [@removed, Date.new(2026, 1, 5), Date.new(2026, 1, 6), 4.0]])
    Issue.where(id: deleted.id).delete_all

    get :index, params: { project_id: @project.id, baseline_id: baseline.id }

    assert_response :success
    assert_equal [@removed.id], controller_ivar(:remove_issues).map(&:id)
  end

  def test_a_user_who_is_not_a_member_is_denied
    @request.session[:user_id] = 3

    get :index, params: { project_id: @project.id, baseline_id: @baseline.id }

    assert_response :forbidden
  end
end
