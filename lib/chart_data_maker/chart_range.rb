module ChartDataMaker
  # Range of the dates on the chart: the label of a date, the start and end dates and the last dates with a value.
  # Extended into ChartDataMaker (and included, for the case the module is mixed in).
  module ChartRange
    # Label of a date on the chart axis (chart.js: milliseconds)
    #
    # @param [Date] date date on the axis
    # @return [Numeric] label
    def chart_label(date)
      date.to_time.to_i * 1000
    end

    # All dates on the chart, from the start date to the end date.
    #
    # @param [CalculateEvm] evm evm calculation object
    # @return [Array] dates
    def chart_dates(evm)
      duration = chart_duration(evm)
      (duration[:start_date]..duration[:end_date]).to_a
    end

    # The last date EV and AC are shown on chart: basis date or finished date, whichever is earlier.
    #
    # @param [CalculateEvm] evm evm calculation object
    # @return [Date] date
    def chart_adjust_date(evm)
      [evm.finished_date, evm.basis_date].compact.min
    end

    # Get duretion of chart
    #
    # @param [CalculateEvm] evm evm calculation object
    # @return [Hash] duration for chart
    def chart_duration(evm)
      { start_date: chart_start_date(evm), end_date: chart_end_date(evm) }
    end

    # Start date of chart
    #
    # @param [CalculateEvm] evm evm calculation object
    # @return [Date] start date
    def chart_start_date(evm)
      min_date = [evm.pv.start_date, evm.pv_actual.start_date, evm.ev.min_date, evm.ac.min_date]
      min_date << evm.pv_baseline.start_date if evm.pv_baseline.present?
      min_date.min
    end

    # End date of chart (the day after the last day with a value)
    #
    # @param [CalculateEvm] evm evm calculation object
    # @return [Date] end date
    def chart_end_date(evm)
      max_date = [evm.pv.due_date, evm.pv_actual.due_date]
      max_date << evm.forecast_finish_date if evm.forecast
      max_date << evm.pv_baseline.due_date if evm.pv_baseline.present?
      [*max_date, *chart_last_value_dates(evm)].compact.max + 1
    end

    # Dates of the last EV and AC shown on chart
    #
    # @param [CalculateEvm] evm evm calculation object
    # @return [Array] last date of EV and last date of AC (nil when no AC before basis date)
    def chart_last_value_dates(evm)
      if evm.finished_date.present?
        [evm.ev.max_date, last_ac_date_before_basis_date(evm)]
      else
        [evm.ev.cumulative.keys.max, evm.ac.cumulative.keys.max]
      end
    end

    # The last date of AC before the basis date
    #
    # @param [CalculateEvm] evm evm calculation object
    # @return [Date] date (nil when no AC before basis date)
    def last_ac_date_before_basis_date(evm)
      evm.ac.cumulative.select { |ac_date, _value| ac_date < evm.basis_date }.keys.max
    end
  end
end
