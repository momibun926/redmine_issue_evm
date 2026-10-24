# Chart data maker
# This module is a function of create data to display chart.
# Requires CalculateEvm class.
#
# Called as ChartDataMaker.evm_chart_data(...) / ChartDataMaker.performance_chart_data(...)
# -- not included into controllers -- since every method here is a pure
# function of its arguments (an already-built CalculateEvm, or plain values):
# no DB access, no Redmine/Rails helpers, nothing controller-specific. See
# the current-state analysis doc, section 4/12: this is the first of the
# lib/ mixins to be moved out of BaseevmController's ancestor chain and into
# an explicit, visible call, per the priority #4 proposal there.
#
# `module_function` below makes every method here both callable as
# ChartDataMaker.foo(...) and (should anything ever `include ChartDataMaker`
# again) a private instance method reachable by its bare name -- which is
# exactly what lets these methods keep calling each other by bare name
# (chart_duration(evm), evm_round(...), ...) unchanged below.
module ChartDataMaker
  module_function

  # Series of the EVM chart, in the order they are returned.
  PLOT_DATA_KIND = %i[labels pv_actual pv_daily pv_baseline ac ev bac eac eac_daily ac_forecast ev_forecast].freeze
  # Series drawn from the daily EVM values
  PLOT_DATA_KIND_EVM = %i[pv_actual pv_daily ac ev eac_daily].freeze
  # Series drawn only when the forecast option is on
  PLOT_DATA_KIND_FORECAST = %i[bac eac ac_forecast ev_forecast].freeze

  # Create data for display chart for chartjs.
  #
  # 1. basis EVM data for chart
  # 2. You chseck forecast option is on, add follows data
  # * BAC top line
  # * EAC top line
  # * forecast AC (forecast finish date)
  # * forecast EV (forecast finish date)
  #
  # @param [CalculateEvm] evm evm calculation object
  # @return [Hash] chart data
  def evm_chart_data(evm)
    plot_data = Hash.new { |h, k| h[k] = [] }
    # start date and end date of chart
    duration = chart_duration(evm)
    add_evm_plot_data(plot_data, evm, duration)
    add_forecast_plot_data(plot_data, evm, duration) if evm.forecast
    # change to JSON
    PLOT_DATA_KIND.each_with_object({}) do |kind, chart_data|
      chart_data[kind] = kind.equal?(:labels) ? plot_data[kind] : plot_data[kind].to_json
    end
  end

  # Add the EVM chart series (PV, AC, EV, ...) of each date in the chart duration.
  #
  # @param [Hash] plot_data series of chart, kind => values of each date
  # @param [CalculateEvm] evm evm calculation object
  # @param [Hash] duration start date and end date for chart
  def add_evm_plot_data(plot_data, evm, duration)
    evm_data_source = create_evm_chart_data_source(evm)
    (duration[:start_date]..duration[:end_date]).each do |chart_date|
      plot_data[:labels] << chart_label(chart_date)
      plot_data[:pv_baseline] << evm_round(evm_data_source[:pv_baseline][chart_date]) if evm.pv_baseline.present?
      add_evm_plot_values(plot_data, evm_data_source, chart_date)
    end
  end

  # Add the values of PV, EV, AC, ... on a date to the EVM chart series.
  #
  # @param [Hash] plot_data series of chart, kind => values of each date
  # @param [Hash] evm_data_source evm data for chart, kind => values of each date
  # @param [Date] chart_date date on the chart
  def add_evm_plot_values(plot_data, evm_data_source, chart_date)
    PLOT_DATA_KIND_EVM.each do |kind|
      plot_data[kind] << evm_round(evm_data_source[kind][chart_date])
    end
  end

  # Add the forecast series (BAC, EAC top line, forecast AC and EV) of each date in the chart duration.
  #
  # @param [Hash] plot_data series of chart, kind => values of each date
  # @param [CalculateEvm] evm evm calculation object
  # @param [Hash] duration start date and end date for chart
  def add_forecast_plot_data(plot_data, evm, duration)
    forecast_data_source = create_forecast_chart_data_source(evm, duration)
    (duration[:start_date]..duration[:end_date]).each do |chart_date|
      PLOT_DATA_KIND_FORECAST.each do |kind|
        plot_data[kind] << evm_round(forecast_data_source[kind][chart_date])
      end
    end
  end

  # Label of a date on the chart axis (chart.js: milliseconds)
  #
  # @param [Date] date date on the axis
  # @return [Numeric] label
  def chart_label(date)
    date.to_time.to_i * 1000
  end

  # Create data for display performance chart.
  #
  # @param [CalculateEvm] evm evm calculation object
  # @return [Hash] data for performance chart
  def performance_chart_data(evm)
    source = performance_chart_source(evm)
    dates = chart_dates(evm)
    { labels: dates.map { |date| chart_label(date) } }.merge(performance_chart_series(dates, *source))
  end

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

  # All dates on the chart, from the start date to the end date.
  #
  # @param [CalculateEvm] evm evm calculation object
  # @return [Array] dates
  def chart_dates(evm)
    duration = chart_duration(evm)
    (duration[:start_date]..duration[:end_date]).to_a
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

  # The last date EV and AC are shown on chart: basis date or finished date, whichever is earlier.
  #
  # @param [CalculateEvm] evm evm calculation object
  # @return [Date] date
  def chart_adjust_date(evm)
    [evm.finished_date, evm.basis_date].compact.min
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

  # create forecast data
  #
  # @param [CalculateEvm] evm evm object
  # @param [Hash] chart_duration start date and end date for chart
  # @return [Hash] forechat data fro chart
  def create_forecast_chart_data_source(evm, chart_duration)
    start_date = chart_duration[:start_date]
    end_date = chart_duration[:end_date]
    {
      # top line of BAC
      bac: { start_date => evm.bac, end_date => evm.bac },
      # top line of EAC
      eac: { start_date => evm.eac, end_date => evm.eac },
      # forecast line of AC
      ac_forecast: { evm.basis_date => evm.today_ac, evm.forecast_finish_date => evm.eac },
      # forecast line of EV
      ev_forecast: { evm.basis_date => evm.today_ev, evm.forecast_finish_date => evm.bac }
    }
  end

  # create evm chart data sourcea
  #
  # @param [CalculateEvm] evm evm object
  # @return [Hash] evm data for chart
  def create_evm_chart_data_source(evm)
    adjust_date = chart_adjust_date(evm)
    ev_hash = evm.ev.cumulative_at(adjust_date)
    ac_hash = evm.ac.cumulative_at(adjust_date)
    pv_chart_data_source(evm).merge(pv_daily: evm.pv.daily,
                                    ev: ev_hash,
                                    ac: ac_hash,
                                    eac_daily: calculate_eac_daily(evm.bac, ev_hash, ac_hash))
  end

  # PV data of actual (and baseline) for chart. Always within due date.
  #
  # @param [CalculateEvm] evm evm object
  # @return [Hash] pv_actual, and pv_baseline when baseline is selected
  def pv_chart_data_source(evm)
    data_source = { pv_actual: evm.pv_actual.cumulative_at(evm.pv_actual.due_date) }
    data_source[:pv_baseline] = evm.pv_baseline.cumulative_at(evm.pv_baseline.due_date) if evm.pv_baseline.present?
    data_source
  end

  # calculate daily EAC
  #
  # @param [Numeric] bac BAC
  # @param [Hash] ev_hash EV adjusted for chart
  # @param [Hash] ac_hash AC adjusted for chart
  # @return [Hash] EAC daily
  def calculate_eac_daily(bac, ev_hash, ac_hash)
    temp_hash = {}
    ev_hash.each do |ev_date, ev_value|
      ac_value = ac_hash.select { |ac_date, _value| ac_date <= ev_date }.values.max
      cpi_value = calculate_spi(ev_value, ac_value)
      temp_hash[ev_date] = ac_value + ((bac - ev_value) / cpi_value) unless cpi_value.nil?
    end
    temp_hash
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
