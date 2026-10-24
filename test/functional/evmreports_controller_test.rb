require File.expand_path("evm_functional_test_helper", __dir__)

# Functional tests of EvmreportsController (EVM report list / new / show /
# edit / create / update / destroy).
class EvmreportsControllerTest < Redmine::ControllerTest
  include EvmFunctionalTestSupport

  def setup
    sign_in_as_project_member
    create_evm_setting
    @baseline = create_baseline("baseline", Time.utc(2026, 1, 1),
                                [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 40.0]])
    @earlier = create_report(Date.new(2026, 1, 2), "report of the 2nd")
    @previous = create_report(Date.new(2026, 1, 5), "report of the 5th")
    @same_day = create_report(Date.new(2026, 1, 8), "report of the 8th")
  end

  def test_index_lists_the_reports_newest_status_date_first
    get :index, params: { project_id: @project.id }

    assert_response :success
    assert_equal [@same_day.id, @previous.id, @earlier.id], controller_ivar(:evm_report).map(&:id)
  end

  # ---- new ---------------------------------------------------------------

  def test_new_converts_the_evm_values_from_hours_to_days
    get :new, params: new_params

    assert_response :success
    report = controller_ivar(:evm_report)
    assert_equal @project.id, report.project_id
    assert_equal @baseline.id, report.baseline_id
    assert_equal Date.new(2026, 1, 8), report.status_date
    assert_equal [7.5, 4.0, 2.5, 2.0, -1.5, 0.5],
                 [report.evm_bac, report.evm_pv, report.evm_ev, report.evm_ac, report.evm_sv, report.evm_cv]
  end

  def test_new_starts_from_the_text_of_the_latest_earlier_report
    get :new, params: new_params

    assert_equal "report of the 5th", controller_ivar(:evm_report).report_text
    assert_equal @previous, controller_ivar(:evm_report_prev)
    assert_equal @baseline, controller_ivar(:evmbaseline)
  end

  def test_new_without_an_earlier_report_starts_with_an_empty_text
    get :new, params: new_params.merge(status_date: "2026-01-01")

    assert_response :success
    assert_nil controller_ivar(:evm_report).report_text
    assert controller_ivar(:evm_report_prev).new_record?
  end

  # ---- show / edit -------------------------------------------------------

  def test_show
    get :show, params: { project_id: @project.id, id: @same_day.id }

    assert_response :success
    assert_equal @same_day, controller_ivar(:evm_report)
    assert_equal @previous, controller_ivar(:evm_report_prev)
    assert_equal @baseline, controller_ivar(:evmbaseline)
  end

  def test_edit
    get :edit, params: { project_id: @project.id, id: @same_day.id }

    assert_response :success
    assert_equal @same_day, controller_ivar(:evm_report)
    assert_equal @previous, controller_ivar(:evm_report_prev)
  end

  # ---- create ------------------------------------------------------------

  def test_create_saves_the_report_for_the_current_user
    assert_difference "ProjectEvmreport.count", 1 do
      post :create, params: { project_id: @project.id, project_evmreport: report_params(Date.new(2026, 1, 9)) }
    end

    assert_redirected_to "/projects/#{@project.id}/evmreports"
    assert_equal I18n.t(:notice_successful_create), flash[:notice]
    report = ProjectEvmreport.find_by!(status_date: Date.new(2026, 1, 9))
    assert_equal [2, 2, 2], [report.create_user_id, report.update_user_id, report.author_id]
    assert_equal [@project.id, @baseline.id, "new text"], [report.project_id, report.baseline_id, report.report_text]
    assert_equal [7.5, 4.0, 2.5, 2.0, -1.5, 0.5],
                 [report.evm_bac, report.evm_pv, report.evm_ev, report.evm_ac, report.evm_sv, report.evm_cv]
    assert_in_delta Time.now.utc, report.created_on, 60
    assert_in_delta Time.now.utc, report.updated_on, 60
  end

  def test_create_replaces_the_report_of_the_same_status_date
    post :create, params: { project_id: @project.id, project_evmreport: report_params(Date.new(2026, 1, 8)) }

    assert_nil ProjectEvmreport.find_by(id: @same_day.id)
    assert_equal 1, ProjectEvmreport.where(project_id: @project.id, status_date: Date.new(2026, 1, 8)).count
    assert_equal 3, ProjectEvmreport.where(project_id: @project.id).count
  end

  # KNOWN BUG (kept as is by the refactoring): on a validation error #create
  # re-renders the form, but the controller keeps the record in a local
  # variable while the view reads @evm_report, so rendering raises (HTTP 500).
  # Nothing is saved. Update this test together with the fix.
  def test_create_without_a_text_saves_nothing_and_fails_to_render_the_form
    assert_no_difference "ProjectEvmreport.count" do
      assert_raises(ActionView::Template::Error) do
        post :create, params: { project_id: @project.id,
                                project_evmreport: report_params(Date.new(2026, 1, 9)).merge(report_text: "") }
      end
    end
  end

  # ---- update ------------------------------------------------------------

  def test_update_changes_the_report_and_records_the_user
    patch :update, params: { project_id: @project.id, id: @same_day.id,
                             project_evmreport: { report_text: "updated text", evm_bac: 9.5 } }

    assert_redirected_to "/projects/#{@project.id}/evmreports"
    assert_equal I18n.t(:notice_successful_update), flash[:notice]
    @same_day.reload
    assert_equal ["updated text", 9.5, 2], [@same_day.report_text, @same_day.evm_bac, @same_day.update_user_id]
    assert_in_delta Time.now.utc, @same_day.updated_on, 60
  end

  # KNOWN BUG (kept as is): same as #create above, for #update.
  def test_update_without_a_text_changes_nothing_and_fails_to_render_the_form
    assert_raises(ActionView::Template::Error) do
      patch :update, params: { project_id: @project.id, id: @same_day.id, project_evmreport: { report_text: "" } }
    end

    assert_equal "report of the 8th", @same_day.reload.report_text
  end

  # ---- destroy -----------------------------------------------------------

  def test_destroy
    assert_difference "ProjectEvmreport.count", -1 do
      delete :destroy, params: { project_id: @project.id, id: @same_day.id }
    end

    assert_redirected_to "/projects/#{@project.id}/evmreports"
    assert_equal I18n.t(:notice_successful_delete), flash[:notice]
  end

  # ---- access control ----------------------------------------------------

  def test_without_the_report_permission_everything_is_denied
    Role.find(1).remove_permission!(:view_project_evmreports)

    get :index, params: { project_id: @project.id }
    assert_response :forbidden
    assert_no_difference "ProjectEvmreport.count" do
      delete :destroy, params: { project_id: @project.id, id: @same_day.id }
    end
    assert_response :forbidden
  end

  private

  def create_report(status_date, text)
    ProjectEvmreport.create!(project_id: @project.id, status_date: status_date, report_text: text,
                             baseline_id: @baseline.id, evm_bac: 1.0, author_id: 3, create_user_id: 3,
                             update_user_id: 3, created_on: Time.utc(2026, 1, 9), updated_on: Time.utc(2026, 1, 9))
  end

  # Values of the main page's report link (hours); working_hours 8h per day
  def new_params
    { project_id: @project.id, baseline_id: @baseline.id, status_date: "2026-01-08", working_hours: 8,
      bac: 60, pv: 32, ev: 20, ac: 16, sv: -12, cv: 4 }
  end

  def report_params(status_date)
    { project_id: @project.id, baseline_id: @baseline.id, status_date: status_date, report_text: "new text",
      evm_bac: 7.5, evm_pv: 4.0, evm_ev: 2.5, evm_ac: 2.0, evm_sv: -1.5, evm_cv: 0.5 }
  end
end
