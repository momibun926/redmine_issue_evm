require File.expand_path("evm_functional_test_helper", __dir__)

# The breakdown pages by parent issue and by version offer the parents and versions of the project
# in the URL. An id that the page does not offer -- one of a project that the user may not see, or
# of another project of the user -- is not found; no EVM is calculated for it and nothing of it
# is shown.
module EvmBreakdownProjectScope
  def self.included(base)
    base.include EvmFunctionalTestSupport
  end

  def setup
    sign_in_as_project_member
    create_evm_setting
    @private = create_private_project
    @other = Project.find(1)
    prepare_scenario
  end

  def test_an_id_of_a_project_that_the_user_may_not_see_is_not_found
    assert_not_found_for private_id
  end

  def test_an_id_of_another_project_of_the_user_is_not_found
    assert_not_found_for other_id
  end

  def test_one_unknown_id_among_known_ones_makes_the_whole_request_not_found
    assert_not_found_for [own_id, private_id]
    assert_not_found_for [other_id, own_id]
  end

  def test_an_id_that_does_not_exist_is_not_found
    assert_not_found_for 999_999
  end

  def test_an_id_the_page_offers_is_still_shown
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", selected_param => [own_id] }

    assert_response :success
    assert_equal [own_id.to_s], controller_ivar(:evm_data).keys
  end

  def test_an_id_sent_as_a_single_value_is_still_shown
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", selected_param => own_id.to_s }

    assert_response :success
    assert_equal [own_id.to_s], controller_ivar(:evm_data).keys
  end

  def test_a_selection_that_is_not_a_list_of_ids_is_not_found
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", selected_param => { "0" => own_id } }

    assert_response :not_found
  end

  private

  def assert_not_found_for(ids)
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", selected_param => Array(ids) }

    assert_response :not_found
    assert_no_match(/#{Regexp.escape(private_name)}/, response.body)
    assert_nil controller_ivar(:evm_data).presence
  end

  # an issue of the project with a start date, a due date and an estimated time
  def create_dated_issue(project, subject, attributes = {})
    create_scenario_issue(project, subject, [Date.new(2026, 1, 5), Date.new(2026, 1, 9)], 40, attributes)
  end
end

class EvmparentissuesProjectScopeTest < Redmine::ControllerTest
  tests EvmparentissuesController
  include EvmBreakdownProjectScope

  def prepare_scenario
    @own = parent_with_child(@project, "Own parent")
    @private_parent = parent_with_child(@private, "Secret parent of the private project")
    @other_parent = parent_with_child(@other, "Parent of another project")
  end

  def selected_param
    :selected_parent_issue_id
  end

  def own_id
    @own.id
  end

  def private_id
    @private_parent.id
  end

  def other_id
    @other_parent.id
  end

  def private_name
    @private_parent.subject
  end

  def test_an_issue_that_is_not_a_parent_is_not_found
    child = @own.children.first

    assert_not_found_for child.id
  end

  private

  def parent_with_child(project, subject)
    parent = create_dated_issue(project, subject)
    child = create_dated_issue(project, "#{subject} child")
    child.reload.update!(parent_issue_id: parent.id)
    parent
  end
end

class EvmversionsProjectScopeTest < Redmine::ControllerTest
  tests EvmversionsController
  include EvmBreakdownProjectScope

  def prepare_scenario
    @own = version_with_issue(@project, "Own release")
    @private_version = version_with_issue(@private, "Secret release of the private project")
    @other_version = version_with_issue(@other, "Release of another project")
  end

  def selected_param
    :selected_version_id
  end

  def own_id
    @own.id
  end

  def private_id
    @private_version.id
  end

  def other_id
    @other_version.id
  end

  def private_name
    @private_version.name
  end

  # A version of a subproject, and a shared one of another project, are used by issues of the project
  # and offered by the page.
  def test_a_version_of_a_subproject_that_the_page_offers_is_shown
    sub = Project.create!(name: "Sub", identifier: "evm-sub", parent_id: @project.id,
                          enabled_module_names: %w[issue_tracking Issuevm])
    version = version_with_issue(sub, "Sub release")

    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", selected_param => [version.id] }

    assert_response :success
    assert_equal [version.id.to_s], controller_ivar(:evm_data).keys
    assert_equal "#{sub.name} #{version.name}", controller_ivar(:evm_data)[version.id.to_s].description.to_s
  end

  private

  def version_with_issue(project, name)
    version = Version.create!(project: project, name: name, effective_date: Date.new(2026, 1, 16))
    create_dated_issue(project, "Issue of #{name}", fixed_version: version)
    version
  end
end
