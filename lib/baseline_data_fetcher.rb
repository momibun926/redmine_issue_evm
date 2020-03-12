# Baseline data fetcher
# This module is a function to collect baseline records necessary to calculate EVM
# It also collects a selectable list that is optionally specified
#
module BaselineDataFetcher
  # Get Issues of Baseline.(start date, due date, estimated hours)
  # When baseline_id is nil,latest baseline of project.
  #
  # @param [numeric] baseline_id baseline id
  # @return [EvmBaseline] evmbaselines
  def project_baseline(baseline_id)
    Evmbaseline.where(id: baseline_id).first.evmbaselineIssues if baseline_id.present?
  end

  # get selectable list of baseline
  #
  # @param [project] proj porject object
  # @return [EvmBaseline] baselines
  def selectable_baseline_list(proj)
    Evmbaseline.where(project_id: proj.id).
      order(created_on: :DESC)
  end
end
