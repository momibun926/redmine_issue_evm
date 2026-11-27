require File.expand_path("../../functional/evm_functional_test_helper", __dir__)

# Shared support for the tests of the REST API of the EVM values:
# GET /projects/:project_id/evms.json (and .xml).
#
# Scenario project (see EvmFunctionalTestSupport#create_evm_scenario_project),
# basis date Thu 2026-01-08, without a baseline:
#   BAC 60h (40h + 20h), PV 32h (4 days x 8h of issue 1),
#   EV 20h (issue 1 is 50% done), AC 16h (8h + 8h).
# The baselines of the tests plan issue 1 for 80h instead of 40h, so the
# PV with a baseline is 64h on the same day.
module EvmsApiTestSupport
  # The fixtures and helpers of the functional tests (they are declared when the module is included)
  def self.included(base)
    base.include EvmFunctionalTestSupport
  end

  # The values of "hours" and "days", in this order
  HOURS_VALUES = %w[bac complete_ev pv ev ac sv cv spi cpi cr etc eac vac tcpi].freeze
  # The values of "earned_schedule", in this order
  EARNED_SCHEDULE_VALUES = %w[sac es at tv tpi teac tvac].freeze
  # The values that are not given once the project is finished
  FORECAST_VALUES = %w[etc eac vac tcpi].freeze

  def setup
    super
    @project = create_evm_scenario_project
    Role.find(1).add_permission!(*EvmFunctionalTestSupport::PLUGIN_PERMISSIONS)
    create_evm_setting
  end

  private

  def evms_path(params = {})
    format = params.delete(:format) || "json"
    query = params.empty? ? "" : "?#{params.to_query}"
    "/projects/#{@project.identifier}/evms.#{format}#{query}"
  end

  def assert_current_issue_values(evm)
    assert_in_delta 60.0, evm["hours"]["bac"]
    assert_in_delta 32.0, evm["hours"]["pv"]
    assert_in_delta 20.0, evm["hours"]["ev"]
    assert_in_delta 16.0, evm["hours"]["ac"]
  end

  # The CalculateEvm object of the main page (the HTML request) for the same request
  def page_project_evm(params)
    log_user("jsmith", "jsmith")
    get "/projects/#{@project.identifier}/evms", params: params
    assert_response :success
    controller.instance_variable_get(:@project_evm)
  end

  # Close issue 1 on 2026-01-09, so that every issue of the scenario is finished
  def finish_scenario
    @issue1.reload
    @issue1.init_journal(User.find(2))
    @issue1.done_ratio = 100
    @issue1.status_id = 5
    @issue1.save!
    @issue1.journals.last.update_columns(created_on: Time.utc(2026, 1, 9, 3)) # rubocop:disable Rails/SkipsModelValidations
    update_issue_columns(@issue1, closed_on: Time.utc(2026, 1, 9, 3))
  end
end
