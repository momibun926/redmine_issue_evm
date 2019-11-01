# common helper.
# this helper is common helper. called other helpers.
#
module CommonHelper
  # SPI color of CSS.
  #
  # @return [String] SPI color
  def spi_color(evm)
    value = case evm.today_spi
            when (@cfg_param[:limit_spi] + 0.01..0.99)
              "class='indicator-orange'"
            when (0.01..@cfg_param[:limit_spi])
              "class='indicator-red'"
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
              "class='indicator-orange'"
            when (0.01..@cfg_param[:limit_cpi])
              "class='indicator-red'"
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
                "class='indicator-orange'"
              when (0.01..@cfg_param[:limit_cr])
                "class='indicator-red'"
              else
                ""
              end
    end
    value.html_safe
  end

  # Get local date time
  #
  # @param [datetime] bldatetime updated or created datetime
  # @return [String] formatted date
  def local_date(bldatetime)
    bldatetime.localtime.strftime("%Y-%m-%d %H:%M:%S") if bldatetime.present?
  end

  # create no date area
  #
  # @param [string] no_data if nno data , true
  # @return [String] html
  def display_no_data(no_data)
    "<p class='nodata'>#{l(:label_no_data)}</p>" if no_data.blank?
  end
end
