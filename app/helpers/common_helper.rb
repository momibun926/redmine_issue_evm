# common helper.
# this helper is common helper. called other helpers.
#
module CommonHelper
  # SPI color of CSS.
  #
  # @param [CalculateEvm] evm calculate evm class
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
  # @param [CalculateEvm] evm calculate evm class
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
  # @param [CalculateEvm] evm calculate evm class
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

  # create no date area
  #
  # @param [string] no_data if nno data , true
  # @return [String] html
  def display_no_data(no_data)
    "<p class='nodata'>#{l(:label_no_data)}</p>" if no_data.blank?
  end

  # Convert date to labels on chart.js
  #
  # @param [date] date date on chart.js eAxis
  # @return [number] data for labels on chart.js
  def convert_to_labels(date)
    date.to_time(:local).to_i * 1000
  end

  # forecast value of project finished
  #
  # @param [date] finished_date finished date of project
  # @param [numeric] evm_value EVN value
  # @return [String] html
  def forecast_value_finished(finished_date, evm_value)
    finished_date.nil? ? evm_value : "-".html_safe
  end

  # Get annotationlabel
  #
  # @param [date] finished_date project finished date
  # @return [String] label name, "Basis date" or "Finished date"
  def basis_date_label(finished_date)
    value = finished_date.nil? ? l(:label_basis_date) : l(:label_finished_date)
    value.html_safe
  end
end
