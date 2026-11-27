require File.expand_path("evm_functional_test_helper", __dir__)

# The EVM of a version on the breakdown page by version is calculated from the issues of the
# project in the URL (and its subprojects) only. A version that another project shares can be
# used by the issues of other projects too; their estimated and spent hours are not shown.
class EvmversionsSharedVersionTest < Redmine::ControllerTest
  tests EvmversionsController
  include EvmFunctionalTestSupport

  def setup
    sign_in_as_project_member
    create_evm_setting
    @owner = Project.create!(name: "Owner of the release", identifier: "evm-owner", is_public: false,
                             enabled_module_names: %w[issue_tracking time_tracking Issuevm], tracker_ids: [1])
    @shared = Version.create!(project: @owner, name: "Shared release", sharing: "system",
                              effective_date: Date.new(2026, 1, 16))
  end

  def test_a_shared_version_counts_only_the_issues_of_the_project
    own = dated_issue(@project, "Own issue", 40)
    create_time_entry(own, Date.new(2026, 1, 6), 8)
    owners = dated_issue(@owner, "Issue of the owner", 100)
    create_time_entry(owners, Date.new(2026, 1, 6), 30)

    evm = evm_of(@shared)

    assert_in_delta 40.0, evm.bac, 0.001
    assert_in_delta 8.0, evm.ac.daily.values.sum, 0.001
  end

  def test_a_shared_version_counts_the_issues_of_the_subprojects
    sub = Project.create!(name: "Sub", identifier: "evm-sub", parent_id: @project.id,
                          enabled_module_names: %w[issue_tracking Issuevm], tracker_ids: [1])
    dated_issue(@project, "Own issue", 40)
    dated_issue(sub, "Issue of the subproject", 16)
    dated_issue(@owner, "Issue of the owner", 100)

    assert_in_delta 56.0, evm_of(@shared).bac, 0.001
  end

  def test_the_description_still_names_the_project_of_the_version
    dated_issue(@project, "Own issue", 40)

    assert_equal "#{@owner.name} #{@shared.name}", evm_of(@shared).description.to_s
  end

  def test_a_version_of_a_subproject_counts_the_issues_of_the_project_that_use_it
    sub = Project.create!(name: "Sub", identifier: "evm-sub", parent_id: @project.id,
                          enabled_module_names: %w[issue_tracking Issuevm], tracker_ids: [1])
    version = Version.create!(project: sub, name: "Sub release", sharing: "tree",
                              effective_date: Date.new(2026, 1, 16))
    dated_issue(sub, "Issue of the subproject", 16, version)
    # reload: adding the subproject moved the project in the tree of projects
    dated_issue(@project.reload, "Own issue", 40, version)

    assert_in_delta 56.0, evm_of(version).bac, 0.001
  end

  private

  def dated_issue(project, subject, hours, version = @shared)
    create_scenario_issue(project, subject, [Date.new(2026, 1, 5), Date.new(2026, 1, 9)], hours,
                          fixed_version: version)
  end

  def evm_of(version)
    get :index, params: { project_id: @project.id, basis_date: "2026-01-08", selected_version_id: [version.id] }

    assert_response :success
    controller_ivar(:evm_data)[version.id.to_s]
  end
end
