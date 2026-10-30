require File.expand_path("evm_functional_test_helper", __dir__)

# A baseline is reached only through the project it belongs to: with the id of a baseline of
# another project, in the URL of a project the user may use, the baseline is not found, and it
# is neither shown nor changed.
class EvmbaselinesControllerProjectScopeTest < Redmine::ControllerTest
  tests EvmbaselinesController
  include EvmFunctionalTestSupport

  def setup
    sign_in_as_project_member
    # of a project that the user is not a member of, and of one the user may also use
    @private = create_baseline("private project", Time.utc(2026, 1, 4), [], create_private_project)
    @member = create_baseline("other project of the user", Time.utc(2026, 1, 5), [], Project.find(1))
  end

  def test_show_and_edit_do_not_find_a_baseline_of_another_project
    [@private, @member].each do |baseline|
      get :show, params: { project_id: @project.id, id: baseline.id }
      assert_response :not_found
      get :edit, params: { project_id: @project.id, id: baseline.id }
      assert_response :not_found
    end
  end

  def test_update_does_not_change_a_baseline_of_another_project
    [@private, @member].each do |baseline|
      patch :update, params: { project_id: @project.id, id: baseline.id, evmbaseline: { subject: "changed" } }

      assert_response :not_found
      assert_not_equal "changed", baseline.reload.subject
    end
  end

  def test_destroy_does_not_delete_a_baseline_of_another_project
    [@private, @member].each do |baseline|
      assert_no_difference "Evmbaseline.count" do
        delete :destroy, params: { project_id: @project.id, id: baseline.id }
      end

      assert_response :not_found
    end
  end

  def test_an_unknown_baseline_is_not_found
    get :show, params: { project_id: @project.id, id: 0 }

    assert_response :not_found
  end
end
