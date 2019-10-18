module BaselineDataFetcher
  # Get Issues of Baseline.(start date, due date, estimated hours)
  # When baseline_id is nil,latest baseline of project.
  #
  # @param [numeric] project_id project id
  # @param [numeric] baseline_id baseline id
  # @return [EvmBaseline] evmbaselines
  def project_baseline(project_id, baseline_id)
    baselines = {}
    return unless Evmbaseline.exists?(project_id: project_id)
    
    baselines = if baseline_id.nil?
                  Evmbaseline.where(project_id: project_id).
                              order(created_on: :DESC)
                else
                  Evmbaseline.where(id: baseline_id)
                end
    baselines.first.evmbaselineIssues
  end

  # get selectable list of baseline
  #
  # @param [numeric] porject porject object
  # @return [EvmBaseline] baselines
  def selectable_baseline_list(porject)
    Evmbaseline.where(project_id: porject.id).
                order(created_on: :DESC)
  end
end
