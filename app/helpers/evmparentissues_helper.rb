# evms helper
module EvmparentissuesHelper
  include CommonHelper
  # Get parent issue
  #
  # @param [numeric] parent_issue_id parent issue id
  # @return [issue] parent issue object
  def parent_issue_subject(parent_issue_id)
    Issue.find(parent_issue_id).subject
  end

  # Get parent issue link
  #
  # @param [numeric] parent_issue_id parent issue id
  # @return [link] parent issue link
  def parent_issue_link(parent_issue_id)
    parent_issue = Issue.find(parent_issue_id)
    link_to(parent_issue_id, issue_path(parent_issue))
  end
end
