module IssueDataFetcher
  # Issues that differ between the current plan and a baseline.
  # Mixed into IssueDataFetcher: the methods use its query helpers (evm_target_condition and others).
  module BaselineDiff
    # new issues with a difference from Baseline
    #
    # @param [Hash] actual_issue issue detail.
    # @param [Hash] baseline_issue baseline detail.
    # @return [Issue] new issue issues.
    def diff_new_issues(actual_issue, baseline_issue)
      ids = actual_issue.keys - baseline_issue.keys
      Issue.find(ids)
    end

    # remove issues with a difference from Baseline
    #
    # @param [Hash] actual_issue issue detail.
    # @param [Hash] baseline_issue baseline detail.
    # @return [Array<Issue>] remove issue issues. An issue that has been deleted
    #   from Redmine is not included, since there is nothing left to show.
    def diff_remove_issues(actual_issue, baseline_issue)
      ids = baseline_issue.keys - actual_issue.keys
      Issue.where(id: ids).index_by(&:id).values_at(*ids).compact
    end

    # modify issues with a difference from Baseline
    #
    # @param [Hash] actual_issue issue detail.
    # @param [Hash] baseline_issue baseline detail.
    # @return [Issue] modify issue issues.
    def diff_modify_issues(actual_issue, baseline_issue)
      ids = []
      (actual_issue.keys & baseline_issue.keys).each do |id|
        ids << id unless actual_issue[id] == baseline_issue[id]
      end
      Issue.find(ids)
    end
  end
end
