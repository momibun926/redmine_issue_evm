require File.expand_path("evm_functional_test_helper", __dir__)

# Functional tests of EvmbaselinesController#create: the copy of the issues'
# plan saved with a baseline.
class EvmbaselinesControllerCreateTest < Redmine::ControllerTest
  tests EvmbaselinesController
  include EvmFunctionalTestSupport

  def setup
    sign_in_as_project_member
  end

  def test_create_copies_the_due_date_of_the_version_for_an_issue_without_one
    version = Version.create!(project: @project, name: "Release 9", effective_date: Date.new(2026, 3, 1))
    update_issue_columns(@issue2, due_date: nil, fixed_version_id: version.id)

    post :create, params: { project_id: @project.id, evmbaseline: { subject: "new baseline", based_on: "2026-01-08" } }

    issues = Evmbaseline.find_by!(subject: "new baseline").evmbaselineIssues.order(:issue_id)
    assert_equal [Date.new(2026, 1, 9), Date.new(2026, 3, 1)], issues.map(&:due_date)
  end

  def test_create_without_issues_saves_a_baseline_without_issues
    Issue.where(project_id: @project.id).delete_all

    post :create, params: { project_id: @project.id, evmbaseline: { subject: "new baseline", based_on: "2026-01-08" } }

    assert_redirected_to "/projects/#{@project.id}/evmbaselines"
    assert_empty Evmbaseline.find_by!(subject: "new baseline").evmbaselineIssues
  end

  def test_a_failed_create_saves_no_baseline_issues
    assert_no_difference "EvmbaselineIssue.count" do
      post :create, params: { project_id: @project.id, evmbaseline: { subject: "", based_on: "2026-01-08" } }
    end
  end
end
