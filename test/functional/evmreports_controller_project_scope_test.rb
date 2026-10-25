require File.expand_path("evm_functional_test_helper", __dir__)

# A report is reached only through the project it belongs to (see the same test of the
# baselines), and it is saved in the project of the URL, whatever project the form says.
class EvmreportsControllerProjectScopeTest < Redmine::ControllerTest
  tests EvmreportsController
  include EvmFunctionalTestSupport

  def setup
    sign_in_as_project_member
    create_evm_setting
    @private_project = create_private_project
    @private = create_report(@private_project)
    @member = create_report(Project.find(1))
  end

  def test_show_and_edit_do_not_find_a_report_of_another_project
    [@private, @member].each do |report|
      get :show, params: { project_id: @project.id, id: report.id }
      assert_response :not_found
      get :edit, params: { project_id: @project.id, id: report.id }
      assert_response :not_found
    end
  end

  def test_update_does_not_change_a_report_of_another_project
    [@private, @member].each do |report|
      patch :update, params: { project_id: @project.id, id: report.id, project_evmreport: { report_text: "changed" } }

      assert_response :not_found
      assert_equal "text", report.reload.report_text
    end
  end

  def test_destroy_does_not_delete_a_report_of_another_project
    [@private, @member].each do |report|
      assert_no_difference "ProjectEvmreport.count" do
        delete :destroy, params: { project_id: @project.id, id: report.id }
      end

      assert_response :not_found
    end
  end

  def test_create_saves_the_report_in_the_project_of_the_url_and_keeps_the_reports_of_the_other_project
    assert_difference "ProjectEvmreport.where(project_id: @project.id).count", 1 do
      post :create, params: { project_id: @project.id,
                              project_evmreport: { project_id: @private_project.id, status_date: "2026-01-08",
                                                   report_text: "new text", evm_bac: 1 } }
    end

    assert ProjectEvmreport.exists?(@private.id), "the report of the other project of the same date is kept"
    assert_equal 1, ProjectEvmreport.where(project_id: @private_project.id).count
  end

  def test_update_keeps_the_report_in_its_project
    report = create_report(@project)

    patch :update, params: { project_id: @project.id, id: report.id,
                             project_evmreport: { project_id: @private_project.id, report_text: "changed" } }

    assert_equal [@project.id, "changed"], [report.reload.project_id, report.report_text]
  end

  private

  def create_report(project)
    ProjectEvmreport.create!(project_id: project.id, status_date: Date.new(2026, 1, 8), report_text: "text",
                             evm_bac: 1.0, author_id: 3, create_user_id: 3, update_user_id: 3,
                             created_on: Time.utc(2026, 1, 9), updated_on: Time.utc(2026, 1, 9))
  end
end
