# common helper.
# this helper is common helper. called other helpers.
#
module CommonHelper
  # performance index content.
  #
  # @param [numeric] value evn value
  # @param [float] limit threthold in configuration
  # @return [String] htm element <td class="color">value</td>
  def performance_indicator(value, limit)
    color = case value
            when (limit + 0.01..0.99)
              "indicator-orange"
            when (0.01..limit)
              "indicator-red"
            else
              ""
            end
    content_tag(:td, value, class: color)
  end

  # create no date area
  #
  # @param [string] no_data if nno data , true
  # @return [String] html
  def display_no_data(no_data)
    content_tag(:p, l(:label_no_data), class: "nodata") if no_data.blank?
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
    value = finished_date.nil? ? evm_value : "-"
    content_tag(:td, value)
  end

  # Get annotationlabel
  #
  # @param [date] finished_date project finished date
  # @return [String] label name, "Basis date" or "Finished date"
  def basis_date_label(finished_date)
    finished_date.nil? ? l(:label_basis_date) : l(:label_finished_date)
  end

  # Get annotationlabel
  #
  # @param [hash] cfg_param params
  # @return [String] html
  def explanation_es_unit(cfg_param)
    value = "#{l(:explanation_es_unit)} "
    value << "(#{l(:label_exclude_holidays)})" if cfg_param[:exclude_holiday]
    content_tag(:p, value)
  end
end
