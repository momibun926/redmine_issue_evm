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
  # The helpers of the chart range and of the performance chart live in their
  # own files (lib/chart_data_maker/). They are extended (ChartDataMaker.foo)
  # and included, so they are reachable by their bare name from the methods
  # below either way. When ChartDataMaker is mixed in, these helpers are public
  # instance methods there (the methods below stay private, see above).
  include ChartRange
  include PerformanceSeries
  extend ChartRange
  extend PerformanceSeries

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

  # Create data for display performance chart.
  #
  # @param [CalculateEvm] evm evm calculation object
  # @return [Hash] data for performance chart
  def performance_chart_data(evm)
    source = performance_chart_source(evm)
    dates = chart_dates(evm)
    { labels: dates.map { |date| chart_label(date) } }.merge(performance_chart_series(dates, *source))
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
end
