# evms helper
module EvmparentissuesHelper
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
  # Get parent issue link
  #
  # @param [numeric] issue_id parent issue id
  # @return [issue] parent issue link
  def parent_issue_link(parent_issue_id)
    parent_issue = Issue.find(parent_issue_id)
    link_to(parent_issue_id, issue_path(parent_issue))
  end
  # Get parent issue
  #
  # @param [numeric] issue_id parent issue id
  # @return [issue] parent issue object
  def parent_issue_subject(parent_issue_id)
    Issue.find(parent_issue_id).subject
  end
end
