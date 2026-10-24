require File.expand_path("evm_functional_test_helper", __dir__)

# Functional tests of EvmbaselinesController (baseline list / new / show /
# edit / create / update / destroy).
class EvmbaselinesControllerTest < Redmine::ControllerTest
  include EvmFunctionalTestSupport

  def setup
    sign_in_as_project_member
    @old = create_baseline("old baseline", Time.utc(2026, 1, 1),
                           [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 40.0]])
    @latest = create_baseline("latest baseline", Time.utc(2026, 1, 3),
                              [[@issue1, Date.new(2026, 1, 5), Date.new(2026, 1, 9), 30.0]])
  end

  def test_index_lists_the_baselines_newest_first
    get :index, params: { project_id: @project.id }

    assert_response :success
    assert_equal [@latest.id, @old.id], controller_ivar(:evm_baselines).map(&:id)
  end

  def test_index_lists_only_the_baselines_of_the_project
    other = create_baseline("other project", Time.utc(2026, 1, 4), [], Project.find(1))

    get :index, params: { project_id: @project.id }

    assert_not_includes controller_ivar(:evm_baselines).map(&:id), other.id
  end

  def test_new_proposes_the_dates_and_hours_of_the_projects_issues
    get :new, params: { project_id: @project.id }

    assert_response :success
    assert_equal Time.zone.today, controller_ivar(:evm_baselines).based_on
    assert_equal Date.new(2026, 1, 5), controller_ivar(:start_date)
    assert_equal Date.new(2026, 1, 16), controller_ivar(:due_date)
    assert_equal 60.0, controller_ivar(:bac)
  end

  def test_show
    get :show, params: { project_id: @project.id, id: @latest.id }

    assert_response :success
    assert_equal @latest, controller_ivar(:evm_baselines)
  end

  def test_edit
    get :edit, params: { project_id: @project.id, id: @latest.id }

    assert_response :success
    assert_equal @latest, controller_ivar(:evm_baselines)
  end

  # ---- create ------------------------------------------------------------

  def test_create_saves_a_baseline_of_the_current_plan
    assert_difference "Evmbaseline.count", 1 do
      assert_difference "EvmbaselineIssue.count", 2 do
        post :create, params: { project_id: @project.id,
                                evmbaseline: { subject: "new baseline", description: "d", based_on: "2026-01-08" } }
      end
    end

    assert_redirected_to "/projects/#{@project.id}/evmbaselines"
    assert_equal I18n.t(:notice_successful_create), flash[:notice]
    baseline = Evmbaseline.find_by!(subject: "new baseline")
    assert_equal @project.id, baseline.project_id
    assert_equal 2, baseline.author_id
    assert_equal I18n.t(:label_current_baseline), baseline.state
    assert_equal "d", baseline.description
    assert_equal Date.new(2026, 1, 8), baseline.based_on
    assert_in_delta Time.now.utc, baseline.updated_on, 60
    issues = baseline.evmbaselineIssues.order(:issue_id)
    assert_equal [@issue1.id, @issue2.id], issues.map(&:issue_id)
    assert_equal [Date.new(2026, 1, 5), Date.new(2026, 1, 12)], issues.map(&:start_date)
    assert_equal [Date.new(2026, 1, 9), Date.new(2026, 1, 16)], issues.map(&:due_date)
    assert_equal [40.0, 20.0], issues.map(&:estimated_hours)
    assert_equal [true, true], issues.map(&:leaf)
  end

  def test_create_marks_the_earlier_baselines_of_the_project_as_old
    post :create, params: { project_id: @project.id, evmbaseline: { subject: "new baseline", based_on: "2026-01-08" } }

    assert_equal [I18n.t(:label_old_baseline)] * 2, [@old.reload.state, @latest.reload.state]
  end

  # KNOWN BUG (kept as is by the refactoring): when validation fails, #create
  # and #update re-render the form, but the controller keeps the record in a
  # local variable while the views read @evm_baselines, so rendering raises
  # "First argument in form cannot contain nil or be empty" (HTTP 500)
  # instead of showing the form with the error. Nothing is saved. Update
  # these two tests together with the fix.
  def test_create_without_a_subject_saves_nothing_and_fails_to_render_the_form
    assert_no_difference "Evmbaseline.count" do
      assert_raises(ActionView::Template::Error) do
        post :create, params: { project_id: @project.id, evmbaseline: { subject: "", based_on: "2026-01-08" } }
      end
    end
  end

  # KNOWN QUIRK (kept as is): the earlier baselines are already marked "old"
  # before the new one is validated, so a failed create leaves no current baseline.
  def test_a_failed_create_still_marks_the_earlier_baselines_as_old
    assert_raises(ActionView::Template::Error) do
      post :create, params: { project_id: @project.id, evmbaseline: { subject: "", based_on: "2026-01-08" } }
    end

    assert_equal [I18n.t(:label_old_baseline)] * 2, [@old.reload.state, @latest.reload.state]
  end

  # ---- update ------------------------------------------------------------

  def test_update_changes_the_baseline
    patch :update, params: { project_id: @project.id, id: @latest.id,
                             evmbaseline: { subject: "renamed", description: "changed" } }

    assert_redirected_to "/projects/#{@project.id}/evmbaselines"
    assert_equal I18n.t(:notice_successful_update), flash[:notice]
    @latest.reload
    assert_equal %w[renamed changed], [@latest.subject, @latest.description]
  end

  def test_update_without_a_subject_changes_nothing_and_fails_to_render_the_form
    assert_raises(ActionView::Template::Error) do
      patch :update, params: { project_id: @project.id, id: @latest.id, evmbaseline: { subject: "" } }
    end

    assert_equal "latest baseline", @latest.reload.subject
  end

  # ---- destroy -----------------------------------------------------------

  def test_destroy_deletes_the_baseline_with_its_issues_and_promotes_the_newest_one
    assert_difference "Evmbaseline.count", -1 do
      assert_difference "EvmbaselineIssue.count", -1 do
        delete :destroy, params: { project_id: @project.id, id: @latest.id }
      end
    end

    assert_redirected_to "/projects/#{@project.id}/evmbaselines"
    assert_equal I18n.t(:notice_successful_delete), flash[:notice]
    assert_nil Evmbaseline.find_by(id: @latest.id)
    assert_equal I18n.t(:label_current_baseline), @old.reload.state
  end

  def test_destroy_promotes_the_newest_of_the_remaining_baselines
    middle = create_baseline("middle baseline", Time.utc(2026, 1, 2), [])

    delete :destroy, params: { project_id: @project.id, id: @latest.id }

    assert_equal [I18n.t(:label_old_baseline), I18n.t(:label_current_baseline)],
                 [@old.reload.state, middle.reload.state]
  end

  # ---- access control ----------------------------------------------------

  def test_the_view_permission_allows_reading_but_not_creating
    Role.find(1).remove_permission!(:manage_evmbaselines)
    Role.find(1).add_permission!(:view_evmbaselines)

    get :index, params: { project_id: @project.id }
    assert_response :success
    get :show, params: { project_id: @project.id, id: @latest.id }
    assert_response :success
    get :new, params: { project_id: @project.id }
    assert_response :forbidden
    assert_no_difference "Evmbaseline.count" do
      post :create, params: { project_id: @project.id, evmbaseline: { subject: "x" } }
    end
    assert_response :forbidden
  end

  def test_without_any_baseline_permission_everything_is_denied
    Role.find(1).remove_permission!(:manage_evmbaselines, :view_evmbaselines)

    get :index, params: { project_id: @project.id }

    assert_response :forbidden
  end
end
