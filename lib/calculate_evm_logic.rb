# Calculation EVM module
module CalculateEvmLogic
  # Calculation EVM class.
  # Calculate EVM and create data for chart
  class CalculateEvm
    include PerformanceIndicators
    include CompletionForecast
    include CsvExport

    # Basis date
    attr_reader :basis_date
    # calculation PV class ojbject, basis
    attr_reader :pv
    # calculation PV(actual) class ojbject
    attr_reader :pv_actual
    # calculation PV(baseline) class ojbject
    attr_reader :pv_baseline
    # calculation EV class ojbject
    attr_reader :ev
    # calculation AC class ojbject
    attr_reader :ac
    # forecast
    attr_reader :forecast
    # description
    attr_accessor :description
    # project finished date
    attr_reader :finished_date
    # Project status
    attr_reader :project_state

    # Constractor
    #
    # @param [evmbaseline] baselines selected baseline.
    # @param [Issue] issues
    # @param [Hash] costs spent time.
    # @param [Hash] options calculationEVM options.
    # @option options [Numeric] working_hours hours per day.
    # @option options [date] basis_date basis date.
    # @option options [bool] forecast forecast of option.
    # @option options [String] etc_method etc method of option.
    # @option options [bool] no_use_baseline no use baseline of option.
    # @option options [bool] exclude_holiday Exclude holiday when calculate PV.
    # @option options [String] holiday region.
    def initialize(baselines, issues, costs, options = {})
      assign_options(options)
      calculate_ev_ac_pv(baselines, issues, costs)
      # Finished date is set when project is finished
      @finished_date = check_finished_date(@ev, @pv)
      # Forecast is invalid when project is finished
      @forecast = false if @finished_date.present?
      # project state, EV and PV
      ev_state = @ev.state(@pv)
      @project_state = [ev_state]
      @project_state << @pv.state if ev_state != :finished
    end

    # Badget at completion.
    # Total hours of issues.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] BAC
    def bac(hours = 1)
      bac = @pv.bac / hours
      bac.round(1)
    end

    # Schadule at completion.
    # This is the original planned completion duration (days) of the project.
    #
    # @return [Numeric] SAC
    def sac
      sac = @pv.sac
      sac.round(1)
    end

    # CompleteEV
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] EV / BAC
    def complete_ev(hours = 1)
      complete_ev = bac(hours).zero? ? 0.0 : (today_ev(hours) / bac(hours)) * 100.0
      complete_ev.round(1)
    end

    # Planed value
    # The work scheduled to be completed by a specified date.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] PV on basis date
    def today_pv(hours = 1)
      pv = @pv.today_value / hours
      pv.round(1)
    end

    # Earned value
    # The work actually completed by the specified date;.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] EV on basis date
    def today_ev(hours = 1)
      ev = @ev.today_value / hours
      ev.round(1)
    end

    # Actual cost
    # The costs actually incurred for the work completed by the specified date.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] AC on basis date
    def today_ac(hours = 1)
      ac = @ac.today_value / hours
      ac.round(1)
    end

    # Scedule variance
    # How much ahead or behind the schedule a project is running.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] EV - PV on basis date
    def today_sv(hours = 1)
      sv = today_ev(hours) - today_pv(hours)
      sv.round(1)
    end

    # Cost variance
    # Cost Variance (CV) is a very important factor to measure project performance.
    # CV indicates how much over - or under-budget the project is.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] EV - AC on basis date
    def today_cv(hours = 1)
      cv = today_ev(hours) - today_ac(hours)
      cv.round(1)
    end

    # Check finished date
    # The date that EV of status date greater than BAC of PV(actual or baseline).
    # Other case, The date that all issue was finished.
    #
    # @param [CalculateEv] calc_ev EV class
    # @param [CalculatePv] calc_pv PV class
    # @return [date] project finished date, nil is not finished.
    def check_finished_date(calc_ev, calc_pv)
      calc_ev.cumulative.select { |_k, v| calc_pv.bac.round(1) <= v }.keys.min
    end

    private

    # Set the calculation options.
    #
    # @param [Hash] options calculationEVM options. See #initialize.
    def assign_options(options)
      @working_hours = options[:working_hours]
      @basis_date = options[:basis_date].to_date
      @forecast = options[:forecast]
      @etc_method = options[:etc_method]
      @exclude_holiday = options[:exclude_holiday]
      @region = options[:region]
    end

    # Calculate EV, AC and PV (actual, and baseline when it is selected).
    #
    # @param [evmbaseline] baselines selected baseline.
    # @param [Issue] issues
    # @param [Hash] costs spent time.
    def calculate_ev_ac_pv(baselines, issues, costs)
      # EV
      @ev = CalculateEv.new(@basis_date, issues)
      # AC
      @ac = CalculateAc.new(@basis_date, costs)
      # PV Actual
      @pv_actual = CalculatePv.new(@basis_date, issues, @region, @exclude_holiday)
      # PV Baseline or PV actual
      @pv_baseline = CalculatePv.new(@basis_date, baselines, @region, @exclude_holiday) if baselines.present?
      @pv = @pv_baseline || @pv_actual
    end
  end
end
