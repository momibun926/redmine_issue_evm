# evms helper
module EvmassigneesHelper
  include CommonHelper
  
  # Get assignee name
  #
  # @param [numeric] assignee_id assignee id
  # @return [String] assignee name, assignee name. "no assigned" if not assigned.
  def assignee_name(assignee_id)
    assignee_id.blank? ? l(:no_assignee) : User.find(assignee_id).name
  end
end
