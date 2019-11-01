require "calculate_pv"
require "calculate_ev"
require "calculate_ac"

# Calculation EVM module
module CalculateEvmLogic
  # Calculation EVM class.
  # Calculate EVM and create data for chart
  class CalculateEvm
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
    
    # Constractor
    #
    # @param [evmbaseline] baselines selected baseline.
    # @param [issue] issues
    # @param [hash] costs spent time.
    # @param [hash] options calculationEVM options.
    # @option options [Numeric] working_hours hours per day.
    # @option options [date] basis_date basis date.
    # @option options [bool] forecast forecast of option.
    # @option options [String] etc_method etc method of option.
    # @option options [bool] no_use_baseline no use baseline of option.
    # @option options [bool] exclude_holiday Exclude holiday when calculate PV.
    # @option options [String] holiday region.
    def initialize(baselines, issues, costs, options = {})
      # set options
      @working_hours = options[:working_hours]
      @basis_date = options[:basis_date].to_date
      @forecast = options[:forecast]
      @etc_method = options[:etc_method]
      @exclude_holiday = options[:exclude_holiday]
      @region = options[:region]
      @no_use_baseline = if baselines.nil?
                           "true"
                         else
                           options[:no_use_baseline] || "false"
                         end                
      # Baseline
      if @no_use_baseline == "true"
        @pv_baseline = nil
      else
        @pv_baseline = CalculatePv.new @basis_date, baselines, @region unless baselines.nil?
      end
      # PV Actual
      @pv_actual = CalculatePv.new @basis_date, issues, @region
      # EV
      @ev = CalculateEv.new @basis_date, issues
      # AC
      @ac = CalculateAc.new @basis_date, costs
      # PV
      @pv = @no_use_baseline ? @pv_actual : @pv_baseline
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

    # CompleteEV
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] EV / BAC
    def complete_ev(hours = 1)
      complete_ev = if bac(hours) == 0.0
                      0.0
                    else
                      (today_ev(hours) / bac(hours)) * 100.0
                    end
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

    # Schedule Performance Indicator
    # Schedule Performance Indicator (SPI) is an index showing
    # the efficiency of the time utilized on the project.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] EV / PV on basis date
    def today_spi(hours = 1)
      spi = if today_ev(hours) == 0.0 || today_pv(hours) == 0.0
              0.0
            else
              today_ev(hours) / today_pv(hours)
            end
      spi.round(2)
    end

    # Cost Performance Indicator
    # Cost Performance Indicator (CPI) is an index showing
    # the efficiency of the utilization of the resources on the project.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] EV / AC on basis date
    def today_cpi(hours = 1)
      cpi = if today_ev(hours) == 0.0 || today_ac(hours) == 0.0
              0.0
            else
              today_ev(hours) / today_ac(hours)
            end
      cpi.round(2)
    end

    # Critical ratio
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] SPI * CPI
    def today_cr(hours = 1)
      cr = today_spi(hours) * today_cpi(hours)
      cr.round(2)
    end

    # Estimate to Complete
    # Estimate to Complete (ETC) is the estimated cost required
    # to complete the remainder of the project.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] (BAC - EV) / CPI
    def etc(hours = 1)
      etc = if today_cpi(hours) == 0.0 || today_cr(hours) == 0.0
              0.0
            else
              div_value = case @etc_method
                          when "method1"
                            1.0
                          when "method2"
                            today_cpi(hours)
                          when "method3"
                            today_cr(hours)
                          else
                            today_cpi(hours)
                          end
              (bac(hours) - today_ev(hours)) / div_value
            end
      etc.round(1)
    end

    # Estimate at Completion
    # Estimate at Completion (EAC) is the estimated cost of the project
    # at the end of the project.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] BAC - EAC
    def eac(hours = 1)
      eac = today_ac(hours) + etc(hours)
      eac.round(1)
    end

    # Variance at Completion
    # Variance at completion (VAC) is the variance
    # on the total budget at the end of the project.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] BAC - EAC
    def vac(hours = 1)
      vac = bac(hours) - eac(hours)
      vac.round(1)
    end

    # forecast date (Delay)
    #
    # @return [numeric] delay days
    def delay
      (forecast_finish_date - @pv.due_date).to_i
    end

    # To Complete Cost Performance Indicator
    # To Complete Cost Performance Indicator (TCPI) is an index showing
    # the efficiency at which the resources on the project should be utilized
    # for the remainder of the project.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] (BAC - EV) / (BAC - AC)
    def tcpi(hours = 1)
      tcpi = if bac(hours) == 0.0
               0.0
             else
               (bac(hours) - today_ev(hours)) / (bac(hours) - today_ac(hours))
             end
      tcpi.round(1)
    end

    # Create data for csv export.
    #
    # @return [hash] csv data
    def to_csv
      Redmine::Export::CSV.generate do |csv|
        # date range
        csv_min_date = [@ev.min_date, @ac.min_date, @pv.start_date].min
        csv_max_date = [@ev.max_date, @ac.max_date, @pv.due_date].max
        evm_date_range = (csv_min_date..csv_max_date).to_a
        # title
        csv << ["DATE", evm_date_range].flatten!
        # set evm values each date
        pv_csv = {}
        ev_csv = {}
        ac_csv = {}
        evm_date_range.each do |csv_date|
          pv_csv[csv_date] = @pv.cumulative_pv[csv_date].nil? ? nil : @pv.cumulative_pv[csv_date].round(2)
          ev_csv[csv_date] = @ev.cumulative_ev[csv_date].nil? ? nil : @ev.cumulative_ev[csv_date].round(2)
          ac_csv[csv_date] = @ac.cumulative_ac[csv_date].nil? ? nil : @ac.cumulative_ac[csv_date].round(2)
        end
        # evm values
        csv << ["PV", pv_csv.values.to_a].flatten!
        csv << ["EV", ev_csv.values.to_a].flatten!
        csv << ["AC", ac_csv.values.to_a].flatten!
      end
    end

    # End of project day.(forecast)
    #
    # @return [date] End of project date
    def forecast_finish_date
                    # already finished project
      finish_date = if complete_ev == 100.0
                      @ev.max_date
                    # not worked yet
                    elsif today_ev == 0.0
                      @pv.due_date
                    # After completion schedule date
                    elsif @pv.due_date < @basis_date
                      @basis_date + rest_days(@pv.cumulative_pv[@pv.due_date],
                                              @ev.cumulative_ev[@ev.max_date],
                                              today_spi,
                                              @working_hours)
                    # before schedule date
                    elsif @basis_date < @pv.start_date
                      @basis_date
                    # After completion schedule date
                    else
                      @pv.due_date + rest_days(today_pv,
                                               today_ev,
                                               today_spi,
                                               @working_hours)
                    end
    end

    # rest days
    #
    # @param [numeric] pv pv
    # @param [numeric] ev ev
    # @param [numeric] spi spi
    # @param [numeric] basis_hours hours of per day is plugin setting
    # @return [date] rest days
    def rest_days(pv, ev, spi, basis_hours)
      ((pv - ev) / spi / basis_hours).round(0)
    end
  end
end
