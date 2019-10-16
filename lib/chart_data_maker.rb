# Chart data maker
module ChartDataMaker

  # Create data for display chart.
  #
  # @param [object] evm calculation EVN object
  # @return [hash] chart data
  def chart_data(evm)
    # overdue?
    if evm.calc_pv.overdue
      planned_value = evm.calc_pv.cumulative_pv.select {|date, _value| date < evm.basis_date }
    else
      planned_value = evm.calc_pv.cumulative_pv
    end
    if evm.calc_bl.nil?
    else
      if evm.calc_bl.overdue
        baseline_value = evm.calc_bl.cumulative_pv.select {|date, _value| date < evm.basis_date }
      else
        baseline_value = evm.calc_bl.cumulative_pv
      end
    end
    chart_data = {}
    chart_data[:planned_value] = convert_to_chart planned_value
    chart_data[:actual_cost] = convert_to_chart evm.calc_ac.cumulative_ac
    chart_data[:earned_value] = convert_to_chart evm.calc_ev.cumulative_ev
    chart_data[:baseline_value] = convert_to_chart baseline_value unless evm.calc_bl.nil?
    chart_data[:planned_value_daily] = convert_to_chart evm.pv.daily_pv
    # for chart
    chart_minimum_date = [evm.pv.start_date, evm.calc_ev.min_date, evm.calc_ac.min_date].min
    chart_maximum_date = [evm.pv.due_date, evm.calc_ev.max_date, evm.calc_ac.max_date, evm.forecast_finish_date].max
    # forecast
    if evm.forecast
      bac_top_line = { chart_minimum_date => evm.bac,
                       chart_maximum_date => evm.bac }
      chart_data[:bac_top_line] = convert_to_chart(bac_top_line)
      eac_top_line = { chart_minimum_date => evm.eac,
                       chart_maximum_date => evm.eac }
      chart_data[:eac_top_line] = convert_to_chart(eac_top_line)
      actual_cost_forecast = { evm.basis_date => evm.today_ac,
                               evm.forecast_finish_date => evm.eac }
      chart_data[:actual_cost_forecast] = convert_to_chart(actual_cost_forecast)
      earned_value_forecast = { evm.basis_date => evm.today_ev,
                                evm.forecast_finish_date => evm.bac }
      chart_data[:earned_value_forecast] = convert_to_chart(earned_value_forecast)
    end
    chart_data
  end
  # Create data for display performance chart.
  #
  # @return [hash] data for performance chart
  def performance_chart_data(evm)
    chart_data = {}
    new_ev = complement_evm_value evm.calc_ev.cumulative_ev
    new_ac = complement_evm_value evm.calc_ac.cumulative_ac
    new_pv = complement_evm_value evm.pv.cumulative_pv
    performance_min_date = [new_ev.keys.min,
                            new_ac.keys.min,
                            new_pv.keys.min].max
    performance_max_date = [new_ev.keys.max,
                            new_ac.keys.max,
                            new_pv.keys.max].min
    spi = {}
    cpi = {}
    cr = {}
    (performance_min_date..performance_max_date).each do |date|
      spi[date] = (new_ev[date] / new_pv[date]).round(2)
      cpi[date] = (new_ev[date] / new_ac[date]).round(2)
      cr[date] = (spi[date] * cpi[date]).round(2)
    end
    chart_data[:spi] = convert_to_chart(spi)
    chart_data[:cpi] = convert_to_chart(cpi)
    chart_data[:cr] = convert_to_chart(cr)
    chart_data
  end

  # Convert to chart. xAxis of Chart is time.
  #
  # @param [hash] data target issues of EVM
  # @return [array] EVM hash. Key:time, Value:EVM value
  def convert_to_chart(data)
    converted = Hash[data.map {|k, v| [k.to_time(:local).to_i * 1000, v] }]
    converted.to_a
  end
  # EVM value of Each date. for performance chart.
  #
  # @param [hash] evm_hash EVM hash
  # @return [hash] EVM value of All date
  def complement_evm_value(evm_hash)
    before_date = evm_hash.keys.min
    before_value = evm_hash[before_date]
    temp = {}
    evm_hash.each do |date, value|
      dif_days = (date - before_date - 1).to_i
      dif_value = (value - before_value) / dif_days
      if dif_days.positive?
        sum_value = 0.0
        (1..dif_days).each do |add_days|
          tmpdate = before_date + add_days
          sum_value += dif_value
          temp[tmpdate] = before_value + sum_value
        end
      end
      before_date = date
      before_value = value
      temp[date] = value
    end
    temp
  end  

end