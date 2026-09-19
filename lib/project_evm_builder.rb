# Builds the project-level CalculateEvm object.
#
# Both EvmsController#create_evm_data (the main EVM page) and
# EvmHookViewListner#view_projects_show_left (the project overview sidebar
# widget) used to independently re-implement the same three steps: look up
# the baseline for a given baseline_id, fetch the project's issues/costs,
# and build a CalculateEvm from them. That duplication is exactly what let
# the two drift apart over time -- see the current-state analysis doc,
# section 2 -- so this module is the one place that logic lives now.
#
# Include it alongside IssueDataFetcher (both EvmsController and
# EvmHookViewListner already do, via BaseevmController / their own
# includes), since #build_project_evm calls straight through to
# #evm_issues / #evm_costs on self -- Ruby resolves a bare *method* call via
# the receiver's ancestor chain at call time, so this works regardless of
# where ProjectEvmBuilder itself is included from. BaselineDataFetcher is
# called explicitly below instead (it is no longer include-based; see that
# file's own comment).
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
