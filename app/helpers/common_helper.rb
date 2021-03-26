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
    tag.td(value, class: color)
  end

  # create no date area
  #
  # @param [string] no_data if nno data , true
  # @return [String] html
  def display_no_data(no_data)
    tag.p(l(:label_no_data), class: "nodata") if no_data.blank?
  end

  # Convert date to labels on chart.js
  #
  # @param [date] date date on chart.js eAxis
  # @return [number] data for labels on chart.js
  def convert_to_labels(date)
    date.to_time.to_i * 1000
  end

  # forecast value of project finished
  #
  # @param [date] finished_date finished date of project
  # @param [numeric] evm_value EVN value
  # @return [String] html
  def forecast_value_finished(finished_date, evm_value)
    value = finished_date.nil? ? evm_value : "-"
    tag.td(value)
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
    tag.p(value)
  end

  # start date difference
  #
  # @param [date] actual_date actual date
  # @param [hash] option_value start date
  # @return [String] html
  def diff_start_date(actual_date, option_value = nil)
    option_value.nil? ? format_date(actual_date) : diff_date(option_value[:start_date], actual_date)
  end

  # due date difference
  #
  # @param [date] actual_date actual date
  # @param [hash] option_value due date
  # @return [String] html
  def diff_due_date(actual_date, option_value = nil)
    option_value.nil? ? format_date(actual_date) : diff_date(option_value[:due_date], actual_date)
  end

  # date difference
  #
  # @param [date] after_date after_date
  # @param [date] before_date before date
  # @return [String] html
  def diff_date(after_date, before_date = nil)
    if before_date == after_date
      format_date(after_date)
    else
      tag.b("#{format_date(before_date)} -> #{format_date(after_date)}")
    end
  end

  # estimate hours difference
  #
  # @param [numeric] actual_hours actual hours
  # @param [hash] option_value base hours
  # @return [String] html
  def diff_estimate_hours(actual_hours, option_value = nil)
    return actual_hours if option_value.nil?

    if option_value[:estimated_hours] == actual_hours
      actual_hours
    else
      tag.b("#{option_value[:estimated_hours]} -> #{actual_hours}")
    end
  end
end
