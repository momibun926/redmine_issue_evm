require File.expand_path("evm_functional_test_helper", __dir__)

# The server only knows its own clock (or the time zone of the account), so the date of the
# device is used as the basis date of a page opened without one: the option field of the
# page carries a script that opens the page again with it (see common/_option_field).
class EvmsControllerBasisDateTest < Redmine::ControllerTest
  # The statement that opens the page again with the basis date of the device
  REOPEN = "window.location.replace".freeze

  tests EvmsController
  include EvmFunctionalTestSupport

  def setup
    sign_in_as_project_member
    create_evm_setting
  end

  def test_the_page_opens_again_with_the_date_of_the_device_when_no_basis_date_is_given
    get :index, params: { project_id: @project.id }

    assert_response :success
    assert_includes response.body, REOPEN
    assert_includes response.body, %(today === "#{User.current.time_to_date(Time.current)}")
  end

  def test_the_page_opens_again_when_the_basis_date_is_blank
    get :index, params: { project_id: @project.id, basis_date: "" }

    assert_includes response.body, REOPEN
  end

  def test_the_page_does_not_open_again_when_a_basis_date_is_given
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    assert_response :success
    assert_not_includes response.body, REOPEN
    assert_select "input#basis_date[value=?]", "2026-01-08"
  end

  def test_the_clear_link_uses_the_date_of_the_device
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08" }

    assert_select "a.icon-reload[onclick*=?]", "evmBrowserToday()"
    assert_select "a.icon-reload[href*=?]", "basis_date=#{User.current.time_to_date(Time.current)}"
  end
end
