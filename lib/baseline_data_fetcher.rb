# Baseline data fetcher
# This module is a function to collect baseline records necessary to calculate EVM
# It also collects a selectable list that is optionally specified
#
# Called as BaselineDataFetcher.project_baseline(...) / .selectable_baseline_list(...)
# -- not included into controllers -- since both methods only ever take an
# explicit id/project and return an ActiveRecord query; nothing here reads
# controller state. See the current-state analysis doc, section 4/12
# (priority #4): moved out of BaseevmController's ancestor chain for the
# same reason as ChartDataMaker.
#
# `module_function` (see ChartDataMaker for why) keeps this usable as a
# mixin too, though nothing in the plugin currently includes it.
module BaselineDataFetcher
  module_function

  # Get Issues of Baseline.(start date, due date, estimated hours)
  # When baseline_id is nil,latest baseline of project.
  #
  # @param [Numeric] baseline_id baseline id
  # @return [EvmBaseline] evmbaselines
  def project_baseline(baseline_id)
    Evmbaseline.where(id: baseline_id).first.evmbaselineIssues if baseline_id.present?
  end

  # get selectable list of baseline
  #
  # @param [Project] proj porject object
  # @return [EvmBaseline] baselines
  def selectable_baseline_list(proj)
    Evmbaseline.where(project_id: proj.id).
      order(created_on: :DESC)
  end
end
