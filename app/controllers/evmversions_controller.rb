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

  def offered_ids
    @selectable_options.map { |issue| issue.fixed_version_id.to_s }
  end

  # The EVM of a version is calculated from the issues of the project in the
  # URL and its subprojects, like the other breakdowns. A version can belong
  # to another project (a subproject, or a project that shares it), but the
  # issues of the other projects that use it are not counted.
  def evm_inputs_for(id)
    version = Version.find(id)
    condition = { fixed_version_id: id }
    description = "#{version.project.name} #{version.name}"
    [evm_issues(@project, condition), evm_costs(@project, condition), description]
  end
end
