# Builds the project-level CalculateEvm object.
#
# Used by both the main EVM page (EvmsController#create_evm_data) and the
# project overview (EvmHookViewListner#view_projects_show_left), so that
# they calculate the same way: look up the baseline, fetch the project's
# issues/costs, and build a CalculateEvm from them.
#
# Include it alongside IssueDataFetcher: #build_project_evm calls
# #evm_issues / #evm_costs on self.
module ProjectEvmBuilder
  # @param [Project] project project (descendants are included, same as
  #   evm_issues/evm_costs).
  # @param [Hash] cfg_param EVM calculation options (see CalculateEvm#initialize).
  #   Only :baseline_id is read directly here; the rest is forwarded as-is.
  # @return [CalculateEvm] project-level EVM
  def build_project_evm(project, cfg_param)
    baselines = BaselineDataFetcher.project_baseline(cfg_param[:baseline_id])
    issues = evm_issues(project)
    actual_cost = evm_costs(project)
    # Fully qualified, not bare CalculateEvm.new: Ruby resolves a bare
    # *constant* lexically (by where the code is textually written), unlike
    # a bare *method* call (resolved via the receiver's ancestor chain at
    # call time, which is why evm_issues/evm_costs above work unqualified).
    # This module is defined at the top level, not lexically inside
    # CalculateEvmLogic, so an unqualified CalculateEvm would raise
    # NameError here regardless of what includes ProjectEvmBuilder.
    CalculateEvmLogic::CalculateEvm.new(baselines, issues, actual_cost, cfg_param)
  end
end
