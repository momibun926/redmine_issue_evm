# common helper.
# this helper is common helper. called other helpers.
#
module CommonHelper
  # performance index content.
  #
  # @param [Numeric] value evn value
  # @param [float] limit Threshold in configuration
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
  # @param [String] no_data if nno data , true
  # @return [String] html
  def display_no_data(no_data)
    tag.p(l(:label_no_data), class: "nodata") if no_data.blank?
  end

  # A chart drawn by the evm-chart Stimulus controller
  # (assets/javascripts/evm_chart_controller.js), the same way as the charts
  # of Redmine itself: the data is in a template, as JSON.
  #
  # @param [String] kind "project", "basic", "assignee" or "performance"
  # @param [Hash] data labels, series and the options of the kind of chart
  # @return [String] html
  def evm_chart_tag(kind, data)
    tag.div(class: "evm-chart", data: { controller: "evm-chart", evm_chart_kind_value: kind }) do
      tag.template(data.to_json, data: { evm_chart_target: "data" }) +
        tag.canvas(width: 900, height: 200, data: { evm_chart_target: "canvas" })
    end
  end

  # Data of a chart of EVM values (see #evm_chart_tag).
  #
  # @param [Hash] chart_data labels and series (see ChartDataMaker.evm_chart_data)
  # @param [Date] basis_date date of the vertical line: the finished date, or the basis date
  # @param [Date, nil] finished_date finished date of the project, if finished
  # @return [Hash] data
  def evm_chart_data(chart_data, basis_date, finished_date)
    { labels: chart_data[:labels], series: chart_data.except(:labels),
      basisDate: (finished_date || basis_date).to_date.iso8601, basisDateLabel: basis_date_label(finished_date) }
  end

  # forecast value of project finished
  #
  # @param [Date] finished_date finished date of project
  # @param [Numeric] evm_value EVN value
  # @return [String] html
  def forecast_value_finished(finished_date, evm_value)
    value = finished_date.nil? ? evm_value : "-"
    tag.td(value)
  end

  # Label of the basis date line on the charts
  #
  # @param [Date] finished_date project finished date
  # @return [String] label name, "Basis date" or "Finished date"
  def basis_date_label(finished_date)
    finished_date.nil? ? l(:label_basis_date) : l(:label_finished_date)
  end

  # Unit of the ES values, shown below the ES table
  #
  # @param [Hash] cfg_param params
  # @return [String] html
  def explanation_es_unit(cfg_param)
    value = "#{l(:explanation_es_unit)} "
    value << "(#{l(:label_exclude_holidays)})" if cfg_param[:exclude_holiday]
    tag.p(value)
  end

  # start date difference
  #
  # @param [Date] actual_date actual date
  # @param [Hash] option_value start date
  # @return [String] html
  def diff_start_date(actual_date, option_value = nil)
    option_value.nil? ? format_date(actual_date) : diff_date(option_value[:start_date], actual_date)
  end

  # due date difference
  #
  # @param [Date] actual_date actual date
  # @param [Hash] option_value due date
  # @return [String] html
  def diff_due_date(actual_date, option_value = nil)
    option_value.nil? ? format_date(actual_date) : diff_date(option_value[:due_date], actual_date)
  end

  # date difference
  #
  # @param [Date] after_date after_date
  # @param [Date] before_date before date
  # @return [String] html
  def diff_date(after_date, before_date = nil)
    if before_date == after_date
      format_date(after_date)
    else
      tag.div("#{format_date(before_date)} -> #{format_date(after_date)}", class: "baseline_diff")
    end
  end

  # estimate hours difference
  #
  # @param [Numeric] actual_hours actual hours
  # @param [Hash] option_value base hours
  # @return [String] html
  def diff_estimate_hours(actual_hours, option_value = nil)
    return actual_hours if option_value.nil?

    if option_value[:estimated_hours] == actual_hours
      actual_hours
    else
      tag.div("#{option_value[:estimated_hours]} -> #{actual_hours}", class: "baseline_diff")
    end
  end
end
