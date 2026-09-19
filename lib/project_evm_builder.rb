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
# Include it alongside IssueDataFetcher and BaselineDataFetcher (both
# EvmsController and EvmHookViewListner already do, via BaseevmController /
# their own includes), since #build_project_evm calls straight through to
# #project_baseline / #evm_issues / #evm_costs on self.
module ProjectEvmBuilder
  # @param [Project] project project (descendants are included, same as
  #   evm_issues/evm_costs).
  # @param [Hash] cfg_param EVM calculation options (see CalculateEvm#initialize).
  #   Only :baseline_id is read directly here; the rest is forwarded as-is.
  # @return [CalculateEvm] project-level EVM
  def build_project_evm(project, cfg_param)
    baselines = project_baseline(cfg_param[:baseline_id])
    issues = evm_issues(project)
    actual_cost = evm_costs(project)
    # Not CalculateEvm.new directly: this module can be included by classes
    # that don't lexically sit inside CalculateEvmLogic (e.g. it is defined
    # at the top level here), and Ruby resolves bare constants lexically,
    # not via the including class's ancestors -- so the unqualified name
    # would not be found even though #include CalculateEvmLogic makes the
    # *methods* available fine.
    CalculateEvmLogic::CalculateEvm.new(baselines, issues, actual_cost, cfg_param)
  end
end
