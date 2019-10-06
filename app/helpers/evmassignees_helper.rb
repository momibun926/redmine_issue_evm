# evms helper
module EvmassigneesHelper
  #
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
  #
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
  #
  # Get assignee name
  #
  # @param [numeric] assignee_id assignee id
  # @return [String] assignee name, assignee name. "no assigned" if not assigned.
  def assignee_name(assignee_id)
    assignee_id.blank? ? l(:no_assignee) : User.find(assignee_id).name
  end
end
