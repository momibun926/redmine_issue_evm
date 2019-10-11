# evms helper
module EvmsHelper
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
  # CR color of CSS.
  #
  # @return [String] CR color
  def cr_color(evm)
    value = ""
    if evm.today_sv < 0.0
      value = case evm.today_cr
      when (@cfg_param[:limit_cr] + 0.01..0.99)
        'class="indicator-orange"'
      when (0.01..@cfg_param[:limit_cr])
        'class="indicator-red"'
      else
        ""
      end
    end
    value.html_safe
  end
  # Get project name
  #
  # @return [String] project name, baseline subject
  def project_chart_name
    name = if @baseline_id.nil?
      @project.name
    else
      @project.name + "- " + @evmbaseline.find(@baseline_id).subject
    end
  end
  # Get local date time
  #
  # @param [datetime] bldatetime updated or created datetime
  # @return [String] formatted date
  def local_date(bldatetime)
    bldatetime.localtime.strftime("%Y-%m-%d %H:%M:%S") if bldatetime.present?
  end
end
