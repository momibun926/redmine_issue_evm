# evms helper
module EvmversionsHelper
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
  # Get project name
  #
  # @param [numeric] ver_id fixed version id
  # @return [String] project name, baseline subject
  def version_chart_name(ver_id)
    ver = Version.find(ver_id)
    pro = Project.find(ver.project_id)
    pro.name + " - " + ver.name
  end
  # Get local date time
  #
  # @param [datetime] bldatetime updated or created datetime
  # @return [String] formatted date
  def local_date(bldatetime)
    bldatetime.localtime.strftime("%Y-%m-%d %H:%M:%S") if bldatetime.present?
  end
end
