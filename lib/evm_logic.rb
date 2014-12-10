module EvmLogic

  class IssueEvm

    def initialize baselines, issues, costs, basis_date, forecast, etc_method, calc_basis_actual, performance
      @basis_date = basis_date
      @forecast = forecast
      @etc_method = etc_method
      @performance = performance

      #PV-ACTUAL
      @pv_actual = calculate_planed_value issues
      #PV-BASELINE
      @pv_baseline = calculate_planed_value baselines
      #PV
      @pv = calc_basis_actual ? @pv_actual : @pv_baseline
      #EV
      @ev = calculate_earned_value issues
      #AC
      @ac = calculate_actual_cost costs

      if @basis_date > @pv.keys.max && @pv[@pv.keys.max] != @ev[@ev.keys.max]
        @pv[@basis_date] = @pv[@pv.keys.max]
        @ev[@basis_date] = @ev[@ev.keys.max]
      end
    end


    def basis_date
      @basis_date
    end


    #BAC
    def bac hours
      bac = @pv[@pv.keys.max] / hours
      bac.round(2)
    end


    #CompleteEV
    def complete_ev hours
      complete_ev = bac(hours) == 0.0 ? 0.0 : (today_ev(hours) / bac(hours)) * 100.0
      complete_ev.round(2)
    end
    

    #PV
    def today_pv hours
      pv = @pv[@basis_date] / hours
      pv.round(2)
    end


    #EV
    def today_ev hours
      ev = @ev[@basis_date] / hours
      ev.round(2)
    end
    

    #AC
    def today_ac hours
      ac = @ac[@basis_date] / hours
      ac.round(2)
    end


    #SV
    def today_sv hours
      sv = today_ev(hours) - today_pv(hours)
      sv.round(2)
    end


    #CV
    def today_cv hours
      cv = today_ev(hours) - today_ac(hours)
      cv.round(2)
    end


    #SPI
    def today_spi hours
      spi = today_ev(hours) == 0.0 || today_pv(hours) == 0.0 ? 0.0 : today_ev(hours) / today_pv(hours)
      spi.round(2)
    end


    #CPI
    def today_cpi hours
      cpi = today_ev(hours) == 0.0 || today_ac(hours) == 0.0 ? 0.0 : today_ev(hours) / today_ac(hours)
      cpi.round(2)
    end


    #CR
    def today_cr hours
      cr = today_spi(hours) * today_cpi(hours)
      cr.round(2)
    end


    #ETC
    def etc hours
      if today_cpi(hours) == 0.0 || today_cr(hours) == 0.0
        etc = 0.0  
      else
        case @etc_method
        when 'method1' then
          etc = (bac(hours) - today_ev(hours))
        when 'method2' then
          etc = (bac(hours) - today_ev(hours)) / today_cpi(hours)
        when 'method3' then
          etc = (bac(hours) - today_ev(hours)) / today_cr(hours)
        else
          etc = (bac(hours) - today_ev(hours)) / today_cpi(hours)
        end
      end
      etc.round(2)
    end
    

    #EAC
    def eac hours
      eac = today_ac(hours) + etc(hours)
      eac.round(2)
    end


    #VAC
    def vac hours
      vac = bac(hours) - eac(hours)
      vac.round(2)
    end


    def delay
      unless forecast_finish_date.nil?
        (forecast_finish_date - @pv.keys.max).to_i
      end 
    end


    #TCPI = (BAC - EV) / (BAC - AC)
    def tcpi hours
      tcpi = (bac(hours) - today_ev(hours)) / (bac(hours) - today_ac(hours))
      tcpi.round(2)
    end
    

    #Create chart data
    def chart_data
      chart_date = {}

      chart_date['planned_value'] = convert_to_chart(@pv_actual)
      chart_date['actual_cost'] = convert_to_chart(@ac)
      chart_date['earned_value'] = convert_to_chart(@ev)
      chart_date['baseline_value'] = convert_to_chart(@pv_baseline)

      if @forecast
        bac_top_line = {chrat_minimum_date => bac(1), chrat_maximum_date => bac(1)}
        chart_date['bac_top_line'] = convert_to_chart(bac_top_line)

        eac_top_line = {chrat_minimum_date => eac(1), chrat_maximum_date => eac(1)}
        chart_date['eac_top_line'] = convert_to_chart(eac_top_line)

        actual_cost_forecast = {@basis_date => today_ac(1), forecast_finish_date => eac(1)}
        chart_date['actual_cost_forecast'] = convert_to_chart(actual_cost_forecast)

        earned_value_forecast = {@basis_date => today_ev(1), forecast_finish_date => @pv[@pv.keys.max]}
        chart_date['earned_value_forecast'] = convert_to_chart(earned_value_forecast)
      end

      if @performance
        calc_performance
        chart_date['spi'] = convert_to_chart(@spi)
        chart_date['cpi'] = convert_to_chart(@cpi)
        chart_date['cr'] = convert_to_chart(@cr)
      end 

      chart_date
    end


    def calc_performance
      @spi = {}
      @cpi = {}
      @cr = {}

      new_ev = make_performance_date @ev
      new_ac = make_performance_date @ac
      new_pv = make_performance_date @pv

      new_ev.each do |date , value|
        @spi[date] = (value / new_pv[date]).round(2) unless new_pv[date].nil? 
        @cpi[date] = (value / new_ac[date]).round(2) unless new_ac[date].nil? 
        @cr[date] = (@spi[date] * @cpi[date]).round(2)
      end

    end


  private

      def calculate_planed_value issues
        temp_pv = {}
        unless issues.nil?
          issues.each do |issue|
            next unless issue.leaf?
            hours_per_day = issue_hours_per_day(issue.estimated_hours ,issue.due_date, issue.start_date)
            (issue.start_date..issue.due_date).each do |key|
              temp_pv[key].nil? ? temp_pv[key] = hours_per_day : temp_pv[key] += hours_per_day
            end
          end
        end 
        # Sort and sum value
        calculate_planed_value = sort_and_sum_evm_hash(temp_pv)
      end


      def calculate_earned_value issues
        temp_ev = {}
        unless issues.nil?
          issues.each do |issue|
            next unless issue.leaf?
            if issue.closed?
                close_date = issue.closed_on.utc.to_date
                temp_ev[close_date].nil? ? temp_ev[close_date] = issue.estimated_hours : temp_ev[close_date] += issue.estimated_hours.to_f
            else
              if issue.done_ratio > 0
                if @basis_date < issue.start_date
                  temp_ev[@basis_date] = (issue.estimated_hours * (issue.done_ratio / 100.0)).to_f
                else
                  hours_per_day = issue_hours_per_day(issue.estimated_hours ,issue.due_date, issue.start_date) * (issue.done_ratio / 100.0)
                  (issue.start_date..issue.due_date).each do |key|
                    temp_ev[key].nil? ? temp_ev[key] = hours_per_day : temp_ev[key] += hours_per_day
                  end 
                end 
              end
            end
          end
        end
        # Sort and sum value
        calculate_earned_value = sort_and_sum_evm_hash(temp_ev)
        calculate_earned_value.delete_if{|key, value| key > @basis_date }
      end


      def calculate_actual_cost costs
        temp_ac = {}
        temp_ac = Hash[costs]
        # Sort and sum value
        calculate_actual_cost = sort_and_sum_evm_hash(temp_ac)
      end


      def convert_to_chart hash_with_data 
        hash_converted = Hash[hash_with_data.map{ |k, v| [k.to_time(:utc).to_i * 1000, v] }]
        hash_converted.to_a
      end


      def sort_and_sum_evm_hash evm_hash 
        temp_hash = {}
        sum_value = 0.0
        if evm_hash.nil? || evm_hash[@basis_date].nil?
          evm_hash[@basis_date] = 0.0
        end        
        evm_hash.sort_by{|key,val| key}.each do |date , value|
          sum_value += value
          temp_hash[date] = sum_value
        end        
        temp_hash
      end
    

      def issue_hours_per_day estimated_hours, due_date, start_date
        (estimated_hours / ((due_date + 1) - start_date)).to_f
      end


      def chrat_minimum_date
        [@pv.keys.min, @ev.keys.min, @ac.keys.min].min
      end


      def chrat_maximum_date
        [@pv.keys.max, @ev.keys.max, @ac.keys.max, forecast_finish_date].max
      end


      def forecast_finish_date
        if today_spi(8) == 0.0
          finish_date = @pv.keys.max
        else
          rest_days =  @pv.reject{|key, value| key <= @basis_date }.size
          finish_date = @basis_date + (rest_days / today_spi(8)).round
        end

      end


      def make_performance_date evm_hash
        temp = {}

        before_date = evm_hash.keys.min
        before_value = evm_hash[evm_hash.keys.min]

        evm_hash.each do |date , value|

          dif_days = ( date - before_date -1 ).to_i
          dif_value = ( value - before_value ) / (date - before_date).to_i

          if dif_days > 0
            sum_value = 0.0
            for add_days in 1..dif_days do
              tmpdate = before_date + add_days
              sum_value += dif_value
              temp[tmpdate] = before_value + sum_value
            end
          end

          before_date = date
          before_value = value

          temp[date] = value

        end

        return temp

      end

  end

end
