# evms helper
module EvmtrackersHelper
  # SPI color of CSS.
  #
  # @return [String] SPI color
  def spi_color(evm)
    value = case evm.today_spi
    when (@cfg_param[:limit_spi] + 0.01..0.99)
      'class="indicator-orange"'
    when (0.01..@cfg_param[:limit_spi])
      'class="indicator-red"'
    else
      ""
    end
    value.html_safe
  end
  # CPI color of CSS.
  #
  # @return [String] CPI color
  def cpi_color(evm)
    value = case evm.today_cpi
    when (@cfg_param[:limit_cpi] + 0.01..0.99)
      'class="indicator-orange"'
    when (0.01..@cfg_param[:limit_cpi])
      'class="indicator-red"'
    else
      ""
    end
    value.html_safe
  end
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
