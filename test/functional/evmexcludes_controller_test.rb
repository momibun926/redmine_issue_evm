require File.expand_path("evm_functional_test_helper", __dir__)

# Functional tests of EvmexcludesController#index: the issues left out of the
# EVM because they have no start date / due date.
class EvmexcludesControllerTest < Redmine::ControllerTest
  include EvmFunctionalTestSupport

  def setup
    sign_in_as_project_member
    create_evm_setting
  end

  def test_lists_the_issues_that_are_not_used_for_the_evm
    no_dates = create_scenario_issue(@project, "No dates", [nil, nil], 5)
    no_due_date = create_scenario_issue(@project, "No due date", [Date.new(2026, 1, 5), nil], 5)

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    assert_response :success
    assert_equal [no_dates.id, no_due_date.id].sort, controller_ivar(:exclude_issues).map(&:id).sort
    assert_equal "2026-01-08", controller_ivar(:cfg_param)[:basis_date]
  end

  def test_an_issue_without_a_due_date_is_used_when_its_version_has_one
    version = Version.find_by!(project_id: @project.id, name: "Release 1")
    create_scenario_issue(@project, "Due date from the version", [Date.new(2026, 1, 5), nil], 5,
                          fixed_version: version)

    get :index, params: { project_id: @project.id }

    assert_empty controller_ivar(:exclude_issues)
  end

  def test_lists_nothing_when_every_issue_is_used
    get :index, params: { project_id: @project.id }

    assert_response :success
    assert_empty controller_ivar(:exclude_issues)
  end

  def test_a_user_who_is_not_a_member_is_denied
    @request.session[:user_id] = 3

    get :index, params: { project_id: @project.id }

    assert_response :forbidden
  end
end
