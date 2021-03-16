# parent issue helper
module EvmparentissuesHelper
  include CommonHelper

  # Get parent issue link
  #
  # @param [Numeric] parent_issue_id parent issue id
  # @return [link] parent issue link
  def parent_issue_link(parent_issue_id)
    link_to(parent_issue_id, issue_path(parent_issue_id))
  end
end
