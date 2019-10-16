# evms helper
module EvmtrackersHelper
  include CommonHelper
  # Get selected trackers name
  #
  # @param [array] ids selected tracker ids
  # @return [String] trackers name
  def selected_trackers_name(ids)
    selected = Tracker.select(:name).where(id: ids)
    tracker_name = ""
    selected.each do |trac|
      tracker_name = tracker_name + trac.to_s + " "
    end
    tracker_name
  end
  
 end
