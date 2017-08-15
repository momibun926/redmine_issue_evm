# Calculation EVM module
module EvmLogic

  # Calculation EVM class.
  # Calculate EVM and create data for chart
  class IssueEvm
    # Constractor
    #
    # @param [evmbaseline] baselines selected baseline.
    # @param [issue] issues
    # @param [hash] costs spent time.
    # @param [hash] options calculationEVM options.
    # @option options [date] basis_date basis date.
    # @option options [bool] forecast forecast of option.
    # @option options [String] etc_method etc method of option.
    # @option options [bool] no_use_baseline no use baseline of option.
    # @option options [Numeric] working_hours hours per day.
    def initialize(baselines, issues, costs, options = {})
      # calculationEVM options
      options.assert_valid_keys(:working_hours,
                                :basis_date,
                                :forecast,
                                :etc_method,
                                :no_use_baseline,
                                :region)
      @basis_hours = options[:working_hours]
      @basis_date = options[:basis_date]
      @forecast = options[:forecast]
      @etc_method = options[:etc_method]
      @holiday_region = options[:region]
      @issue_max_date = issues.maximum(:due_date)
      @issue_max_date ||= baselines.maximum(:due_date) unless baselines.nil?
      @issue_max_date ||= issues.maximum(:effective_date)
      # PV-ACTUAL for chart
      @pv_actual_daily = calculate_planed_value issues
      @pv_actual = sort_and_sum_evm_hash @pv_actual_daily
      # PV-BASELINE for chart
      @pv_baseline_daily = calculate_planed_value baselines
      @pv_baseline = sort_and_sum_evm_hash @pv_baseline_daily
      # PV
      @pv = options[:no_use_baseline] ? @pv_actual : @pv_baseline
      # EV
      @ev = calculate_earned_value issues
      # AC
      @ac = calculate_actual_cost costs
      # max date of evm
      pv_max_date = @pv.keys.max
      ev_max_date = @ev.keys.max
      ac_max_date = @ac.keys.max
      # Project finished?
      if (@pv_actual[@pv_actual.keys.max] == @ev[@ev.keys.max]) || (@pv_baseline[@pv_baseline.keys.max] == @ev[@ev.keys.max])
        delete_basis_date = [pv_max_date, ev_max_date, ac_max_date].max
        [@pv, @ev, @ac, @pv_actual, @pv_baseline].each do |evm_hash|
          evm_hash.delete_if { |date, _value| date > delete_basis_date }
        end
        # when project is finished, forecast is disable.
        @forecast = false
      end
      # To calculate the EVM value
      pv_value_date = @pv.select {|k, v| k <= @basis_date}
      @pv_value = @pv[pv_value_date.keys.max] || @pv[pv_max_date]
      ev_value_date = @ev.select {|k, v| k <= @basis_date}
      @ev_value = @ev[ev_value_date.keys.max] || @ev[ev_max_date]
      ac_value_date = @ac.select {|k, v| k <= @basis_date}
      @ac_value = @ac[ac_value_date.keys.max] || @ac[ac_max_date]
    end

    # Basis date
    attr_reader :basis_date

    # Badget at completion.
    # Total hours of issues.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] BAC
    def bac(hours = 1)
      bac = @pv[@pv.keys.max] / hours
      bac.round(1)
    end

    # CompleteEV
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] EV / BAC
    def complete_ev(hours = 1)
      if bac(hours) == 0.0
        complete_ev = 0.0
      else
        complete_ev = (today_ev(hours) / bac(hours)) * 100.0
      end
      complete_ev.round(1)
    end

    # Planed value
    # The work scheduled to be completed by a specified date.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] PV on basis date
    def today_pv(hours = 1)
      pv = @pv_value / hours
      pv.round(1)
    end

    # Earned value
    # The work actually completed by the specified date;.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] EV on basis date
    def today_ev(hours = 1)
      ev = @ev_value / hours
      ev.round(1)
    end

    # Actual cost
    # The costs actually incurred for the work completed by the specified date.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] AC on basis date
    def today_ac(hours = 1)
      ac = @ac_value / hours
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
      if today_ev(hours) == 0.0 || today_pv(hours) == 0.0
        spi = 0.0
      else
        spi = today_ev(hours) / today_pv(hours)
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
      if today_ev(hours) == 0.0 || today_ac(hours) == 0.0
        cpi = 0.0
      else
        cpi = today_ev(hours) / today_ac(hours)
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
      if today_cpi(hours) == 0.0 || today_cr(hours) == 0.0
        etc = 0.0
      else
        case @etc_method
        when 'method1' then
          div_value = 1.0
        when 'method2' then
          div_value = today_cpi(hours)
        when 'method3' then
          div_value = today_cr(hours)
        else
          div_value = today_cpi(hours)
        end
        etc = (bac(hours) - today_ev(hours)) / div_value
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
      (forecast_finish_date(@basis_hours) - @pv.keys.max).to_i
    end

    # To Complete Cost Performance Indicator
    # To Complete Cost Performance Indicator (TCPI) is an index showing
    # the efficiency at which the resources on the project should be utilized
    # for the remainder of the project.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] (BAC - EV) / (BAC - AC)
    def tcpi(hours = 1)
      if bac(hours) == 0.0
        tcpi = 0.0
      else
        tcpi = (bac(hours) - today_ev(hours)) / (bac(hours) - today_ac(hours))
      end
      tcpi.round(1)
    end

    # Create data for display chart.
    #
    # @return [hash] chart data
    def chart_data
      chart_data = {}
      if @issue_max_date < @basis_date && complete_ev < 100.0
        @ev[@basis_date] = @ev[@ev.keys.max]
        @ac[@basis_date] = @ac[@ac.keys.max]
      end
      chart_data[:planned_value] = convert_to_chart(@pv_actual)
      chart_data[:actual_cost] = convert_to_chart(@ac)
      chart_data[:earned_value] = convert_to_chart(@ev)
      chart_data[:baseline_value] = convert_to_chart(@pv_baseline)
      chart_data[:planned_value_daily] = convert_to_chart(@pv_actual_daily)
      if @forecast
        bac_top_line = { chart_minimum_date => bac,
                         chart_maximum_date => bac }
        chart_data[:bac_top_line] = convert_to_chart(bac_top_line)
        eac_top_line = { chart_minimum_date => eac,
                         chart_maximum_date => eac }
        chart_data[:eac_top_line] = convert_to_chart(eac_top_line)
        actual_cost_forecast = { @basis_date => today_ac,
                                 forecast_finish_date(@basis_hours) => eac }
        chart_data[:actual_cost_forecast] = convert_to_chart(actual_cost_forecast)
        earned_value_forecast = { @basis_date => today_ev,
                                  forecast_finish_date(@basis_hours) => bac }
        chart_data[:earned_value_forecast] = convert_to_chart(earned_value_forecast)
      end
      chart_data
    end

    # Create data for display performance chart.
    #
    # @return [hash] data for performance chart
    def performance_chart_data
      chart_data = {}
      new_ev = complement_evm_value @ev
      new_ac = complement_evm_value @ac
      new_pv = complement_evm_value @pv
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

    # Create data for csv export.
    #
    # @return [hash] csv data
    def to_csv
      Redmine::Export::CSV.generate do |csv|
        # date range
        csv_min_date = [@ev.keys.min, @ac.keys.min, @pv.keys.min].min
        csv_max_date = [@ev.keys.max, @ac.keys.max, @pv.keys.max].max
        evm_date_range = (csv_min_date..csv_max_date).to_a
        # title
        csv << ['DATE', evm_date_range].flatten!
        # set evm values each date
        pv_csv = {}
        ev_csv = {}
        ac_csv = {}
        evm_date_range.each do |csv_date|
          pv_csv[csv_date] = @pv[csv_date].nil? ? nil : @pv[csv_date].round(2)
          ev_csv[csv_date] = @ev[csv_date].nil? ? nil : @ev[csv_date].round(2)
          ac_csv[csv_date] = @ac[csv_date].nil? ? nil : @ac[csv_date].round(2)
        end
        # evm values
        csv << ['PV', pv_csv.values.to_a].flatten!
        csv << ['EV', ev_csv.values.to_a].flatten!
        csv << ['AC', ac_csv.values.to_a].flatten!
      end
    end

    private

    # Calculate PV.
    #
    # @param [issue] issues target issues of EVM
    # @return [hash] EVM hash. Key:Date, Value:PV of each days
    def calculate_planed_value(issues)
      temp_pv = {}
      unless issues.nil?
        issues.each do |issue|
          issue.due_date ||= Version.find(issue.fixed_version_id).effective_date
          pv_days = working_days issue.start_date,
                                 issue.due_date
          hours_per_day = issue_hours_per_day issue.estimated_hours.to_f,
                                              pv_days.length
          pv_days.each do |date|
            temp_pv[date] += hours_per_day unless temp_pv[date].nil?
            temp_pv[date] ||= hours_per_day
          end
        end
      end
      temp_pv
    end

    # Calculate EV.
    # Only closed issues.
    #
    # @param [issue] issues target issues of EVM
    # @return [hash] EVM hash. Key:Date, Value:EV of each days
    def calculate_earned_value(issues)
      ev = {}
      ev[@basis_date] ||= 0.0
      unless issues.nil?
        issues.each do |issue|
          # closed issue
          if issue.closed?
          	closed_date = issue.closed_on || issue.updated_on
            dt = closed_date.to_time.to_date
            ev[dt] += issue.estimated_hours.to_f unless ev[dt].nil?
            ev[dt] ||= issue.estimated_hours.to_f
          # progress issue
          elsif issue.done_ratio > 0
            hours = issue.estimated_hours.to_f * issue.done_ratio / 100.0
            start_date = [issue.start_date, @basis_date].min
            issue.due_date ||= Version.find(issue.fixed_version_id).effective_date
            end_date = [issue.due_date, @basis_date].max
            ev_days = (start_date..end_date).to_a
            hours_per_day = issue_hours_per_day hours,
                                                ev_days.length
            ev_days.each do |date|
              ev[date] += hours_per_day unless ev[date].nil?
              ev[date] ||= hours_per_day
            end
          end
        end
      end
      calculate_earned_value = sort_and_sum_evm_hash ev
      calculate_earned_value.delete_if { |date, _value| date > @basis_date }
    end

    # Calculate AC.
    # Spent time of target issues.
    #
    # @param [array] costs target issues of EVM. spent_on and sum of spent_time.
    # @return [hash] EVM hash. Key:Date, Value:AC of each days
    def calculate_actual_cost(costs)
      calculate_actual_cost = sort_and_sum_evm_hash Hash[costs]
      calculate_actual_cost.delete_if { |date, _value| date > @basis_date }
    end

    # Convert to chart. xAxis of Chart is time.
    #
    # @param [hash] data target issues of EVM
    # @return [array] EVM hash. Key:time, Value:EVM value
    def convert_to_chart(data)
      converted = Hash[data.map { |k, v| [k.to_time(:local).to_i * 1000, v] }]
      converted.to_a
    end

    # Sort key value. key value is DATE.
    # Assending date.
    #
    # @param [hash] evm_hash target issues of EVM
    # @return [hash] Sorted EVM hash. Key:time, Value:EVM value
    def sort_and_sum_evm_hash(evm_hash)
      temp_hash = {}
      if evm_hash.blank?
        evm_hash[@basis_date] ||= 0.0
      end
      sum_value = 0.0
      evm_hash.sort_by { |key, _val| key }.each do |date, value|
        sum_value += value
        temp_hash[date] = sum_value
      end
      temp_hash
    end

    # Estimated time per day.
    #
    # @param [Numeric] estimated_hours estimated hours
    # @param [Numeric] days working days
    def issue_hours_per_day(estimated_hours, days)
      (estimated_hours || 0.0) / days
    end

    # working days.
    # exclude weekends and holiday.
    #
    # @param [date] start_date start date of issue
    # @param [date] end_date end date of issue
    # @return [Array] working days
    def working_days(start_date, end_date)
      issue_days = (start_date..end_date).to_a
      working_days = issue_days.reject{|e| e.wday == 0 || e.wday == 6 || e.holiday?(@holiday_region)}
      working_days.length == 0 ? issue_days : working_days
    end

    # Minimam date of chart.
    #
    # @return [date] Most minimum date of PV,EV,AC
    def chart_minimum_date
      [@pv.keys.min,
       @ev.keys.min,
       @ac.keys.min].min
    end

    # Maximum date of chart.
    #
    # @return [date] Most maximum date of PV,EV,AC,End date of forecast
    def chart_maximum_date
      [@pv.keys.max,
       @ev.keys.max,
       @ac.keys.max,
       forecast_finish_date(@basis_hours)].max
    end

    # End of project day.(forecast)
    #
    # @param [numeric] basis_hours hours of per day is plugin setting
    # @return [date] End of project date
    def forecast_finish_date(basis_hours)
      # already finished project
      if complete_ev == 100.0
        @ev.keys.max
      #not worked yet
      elsif today_ev == 0.0
        @pv.keys.max
      #After completion schedule date
      elsif @pv.keys.max < @basis_date
        @basis_date + rest_days(@pv[@pv.keys.max],
                                @ev[@ev.keys.max],
                                today_spi,
                                basis_hours)
      #Before completion schedule date
      else
        @pv.keys.max + rest_days(today_pv,
                                 today_ev,
                                 today_spi,
                                 basis_hours)
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
        if dif_days > 0
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
end
