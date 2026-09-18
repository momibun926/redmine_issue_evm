# Version controller.
# This controller provides the "EVM broken down by version" view.
# See EvmBreakdownController for the shared index/create_evm_data logic.
#
class EvmversionsController < EvmBreakdownController
  menu_item :issuevm

  private

  def breakdown_param
    :selected_version_id
  end

  def selectable_options
    selectable_version_list(@project)
  end

  def evm_inputs_for(id)
    version = Version.find(id)
    # a version can belong to a different (sub)project than the current one
    project = Project.find(version.project_id)
    condition = { fixed_version_id: id }
    description = "#{project.name} #{version.name}"
    [evm_issues(project, condition), evm_costs(project, condition), description]
  end
end
