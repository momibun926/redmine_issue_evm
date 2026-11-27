require File.expand_path("evms_api_test_helper", __dir__)

# REST API of the EVM values: authentication, permissions and errors.
class EvmsApiErrorsTest < Redmine::ApiTest::Base
  include EvmsApiTestSupport

  def test_the_api_key_in_the_parameter
    key = User.find(2).api_key

    get evms_path(basis_date: "2026-01-08", key: key)

    assert_response :success
  end

  def test_a_basis_date_that_is_not_given_is_today
    travel_to Time.utc(2026, 1, 8, 12, 0, 0) do
      get evms_path, headers: credentials("jsmith")
    end

    assert_response :success
    assert_equal "2026-01-08", response.parsed_body["evm"]["basis_date"]
  end

  def test_an_unknown_baseline_option_is_an_error
    %w[previous LATEST].each do |value|
      get evms_path(baseline: value), headers: credentials("jsmith")

      assert_response :unprocessable_content, value
      assert_equal ["Baseline must be latest or none."], response.parsed_body["errors"]
    end

    get evms_path, params: { baseline: ["none"] }, headers: credentials("jsmith")

    assert_response :unprocessable_content
  end

  def test_a_basis_date_that_is_not_a_date_is_an_error
    get evms_path(basis_date: "2026-02-30"), headers: credentials("jsmith")

    assert_response :unprocessable_content
    assert_equal ["Basis date is not a valid date."], response.parsed_body["errors"]
  end

  def test_both_errors_are_given
    get evms_path(basis_date: "abc", baseline: "abc"), headers: credentials("jsmith")

    assert_response :unprocessable_content
    assert_equal 2, response.parsed_body["errors"].length
  end

  def test_a_project_without_the_evm_setting_is_an_error
    Evmsetting.where(project_id: @project.id).delete_all

    get evms_path, headers: credentials("jsmith")

    assert_response :unprocessable_content
    assert_equal ["The EVM setting of this project has not been made."], response.parsed_body["errors"]
  end

  def test_the_api_needs_authentication
    get evms_path(basis_date: "2026-01-08")

    assert_response :unauthorized
  end

  def test_the_api_needs_the_permission
    Role.find(1).remove_permission!(:view_evms)

    get evms_path(basis_date: "2026-01-08"), headers: credentials("jsmith")

    assert_response :forbidden
  end

  def test_the_api_is_not_for_users_who_are_not_members
    get evms_path(basis_date: "2026-01-08"), headers: credentials("dlopper", "foo")

    assert_response :forbidden
  end

  def test_the_api_is_not_available_when_the_rest_api_is_disabled
    Setting.rest_api_enabled = "0"

    get evms_path(basis_date: "2026-01-08"), headers: credentials("jsmith")

    assert_response :forbidden
  end

  def test_an_unknown_project_is_not_found
    get "/projects/no-such-project/evms.json", headers: credentials("jsmith")

    assert_response :not_found
  end
end
