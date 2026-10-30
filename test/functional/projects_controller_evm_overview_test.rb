require File.expand_path("evm_functional_test_helper", __dir__)

# The EVM box on the overview page of a project (the hook view_projects_show_left) has an
# icon in front of its heading, in the style of the other boxes of the page.
class ProjectsControllerEvmOverviewTest < Redmine::ControllerTest
  tests ProjectsController
  include EvmFunctionalTestSupport

  def setup
    # Redmine registers a hook listener when its class is loaded (the test environment does not
    # load the classes of lib/ before they are used)
    EvmHookViewListner.instance
    sign_in_as_project_member
    create_evm_setting
  end

  def test_the_heading_of_the_evm_box_has_an_icon
    get :show, params: { id: @project.id }

    assert_response :success
    heading = css_select("div.issues.box h3.icon").find { |h| h.text.strip == "EVM" }
    assert heading, "no heading EVM"
    assert_equal "svg", heading.children.first.name
    assert_match(/#icon--issue\z/, heading.at("use")["href"])
  end
end
