module ChartDataMaker
  # Series of the performance chart (SPI, CPI, CR), the interpolation of the values between dates and the rounding.
  # Extended into ChartDataMaker (and included, for the case the module is mixed in).
  module PerformanceSeries
    # SPI, CPI and CR of each date for performance chart.
    #
    # @param [Array] dates all dates on the chart
    # @param [Hash] new_ev EV of all dates
    # @param [Hash] new_ac AC of all dates
    # @param [Hash] new_pv PV of all dates
    # @return [Hash] spi, cpi and cr (JSON)
    def performance_chart_series(dates, new_ev, new_ac, new_pv)
      {
        spi: dates.map { |date| calculate_spi(new_ev[date], new_pv[date]) }.to_json,
        cpi: dates.map { |date| calculate_cpi(new_ev[date], new_ac[date]) }.to_json,
        cr: dates.map { |date| calculate_cr(new_ev[date], new_ac[date], new_pv[date]) }.to_json
      }
    end

    # EV, AC and PV of all dates for performance chart.
    #
    # @param [CalculateEvm] evm evm calculation object
    # @return [Array] EV, AC and PV hash. Key:Date, Value:cumulative value of each days
    def performance_chart_source(evm)
      adjust_date = chart_adjust_date(evm)
      [complement_evm_value(evm.ev.cumulative_at(adjust_date)),
       complement_evm_value(evm.ac.cumulative_at(adjust_date)),
       complement_evm_value(evm.pv.cumulative)]
    end

    # EVM value of Each date. for performance chart.
    #
    # @param [Hash] evm_hash EVM hash
    # @return [Hash] EVM value of All date
    def complement_evm_value(evm_hash)
      before_date = evm_hash.keys.min
      before_value = evm_hash[before_date]
      evm_hash.each_with_object({}) do |(date, value), temp|
        dif_days = (date - before_date - 1).to_i
        temp.merge!(interpolate_evm_value(before_date, before_value, dif_days, (value - before_value) / dif_days))
        before_date = date
        before_value = value
        temp[date] = value
      end
    end

    # EVM value of the days between two dates, on a straight line.
    #
    # @param [Date] before_date previous date which has the value
    # @param [Numeric] before_value value of the previous date
    # @param [Numeric] dif_days days between the dates (exclude both)
    # @param [Numeric] dif_value difference of value per a day
    # @return [Hash] EVM value of the days between. empty when there is no day between.
    def interpolate_evm_value(before_date, before_value, dif_days, dif_value)
      sum_value = 0.0
      (1..dif_days).each_with_object({}) do |add_days, filled|
        sum_value += dif_value
        filled[before_date + add_days] = before_value + sum_value
      end
    end

    # round function for evm value
    #
    # @param [number] evm_value EVM hash value
    # @return [number] rounded EVM value or nil
    def evm_round(evm_value)
      evm_value.presence&.round(2)
    end

    # calculate spi
    #
    # @param [Numeric] ev_value EV value at the day
    # @param [Numeric] pv_value PV value at the day
    # @return [float] SPI
    def calculate_spi(ev_value, pv_value)
      if ev_value.nil? || pv_value.nil?
        nil
      else
        evm_round(ev_value / pv_value)
      end
    end

    # calculate cpi
    #
    # @param [Numeric] ev_value EV value at the day
    # @param [Numeric] ac_value AC value at the day
    # @return [float] CPI
    def calculate_cpi(ev_value, ac_value)
      if ev_value.nil? || ac_value.nil?
        nil
      else
        evm_round(ev_value / ac_value)
      end
    end

    # calculate cr
    #
    # @param [Numeric] ev_value EV value at the day
    # @param [Numeric] ac_value AC value at the day
    # @param [Numeric] pv_value PV value at the day
    # @return [float] CR
    def calculate_cr(ev_value, ac_value, pv_value)
      if ev_value.nil? || ac_value.nil? || pv_value.nil?
        nil
      else
        evm_round((ev_value / pv_value) * (ev_value / ac_value))
      end
    end
  end
end
