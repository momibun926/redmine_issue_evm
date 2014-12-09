module EvmLogic

  class IssueEvm

    def initialize baselines, issues, costs, basis_date, forecast, etc_method, calc_basis_actual
      @basis_date = basis_date
      @forecast = forecast
      @etc_method = etc_method

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

      #今日が最大日を超えていたら、今日に最大値をセット
      if @basis_date > @pv.keys.max && @pv[@pv.keys.max] != @ev[@ev.keys.max]
        @pv[@basis_date] = @pv[@pv.keys.max]
        @ev[@basis_date] = @ev[@ev.keys.max]
      end

    end

    #基準日
    def basis_date
      @basis_date
    end

    #BAC
    #予定総工数
    def bac hours
      bac = @pv[@pv.keys.max] / hours
      bac.round(2)
    end

    #CompleteEV
    #BACに対する出来高完了率
    def complete_ev hours
      complete_ev = bac(hours) == 0 ? 0.0 : today_ev(hours) / bac(hours)
      complete_ev.round(2)
    end
    
    #PV
    #基準日時点のPV
    def today_pv hours
      pv = @pv[@basis_date] / hours
      pv.round(2)
    end

    #EV
    #基準日時点のEV
    def today_ev hours
      ev = @ev[@basis_date] / hours
      ev.round(2)
    end
    
    #AC
    #基準日時点のAC
    def today_ac hours
      ac = @ac[@basis_date] / hours
      ac.round(2)
    end

    #SV
    #スケジュール差異(EV-PV)
    def today_sv hours
      sv = today_ev(hours) - today_pv(hours)
      sv.round(2)
    end

    #CV
    #コスト差異(EV-AC)
    def today_cv hours
      cv = today_ev(hours) - today_ac(hours)
      cv.round(2)
    end

    #SPI
    #スケジュールパフォーマンス(EV/PV)
    def today_spi hours
      spi = today_ev(hours) == 0.0 || today_pv(hours) == 0.0 ? 0.0 : today_ev(hours) / today_pv(hours)
      spi.round(2)
    end

    #CPI
    #コストパフォーマンス(EV/AC)
    def today_cpi hours
      cpi = today_ev(hours) == 0.0 || today_ac(hours) == 0.0 ? 0.0 : today_ev(hours) / today_ac(hours)
    end

    #CR
    #プロジェクトパフォーマンス(SPI*CPI)
    def today_cr hours
      cr = today_spi(hours) * today_cpi(hours)
      cr.round(2)
    end

    #ETC
    #(BAC－EV)/CPI
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
    #AC＋ETC
    def eac hours
      eac = today_ac(hours) + etc(hours)
      eac.round(2)
    end

    #VAC
    #BAC－EAC
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
      tcpi.nan? ? 0 : tcpi.round(2)
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

      chart_date
    end

    private

      def calculate_planed_value issues
        temp_pv = {}
        unless issues.nil?
          issues.each do |issue|
            #親チケットは除外
            next unless issue.leaf?
            #一日当たりの時間
            hours_per_day = issue_hours_per_day(issue.estimated_hours ,issue.due_date, issue.start_date)
            #チケットの期間の日毎に一日当たりの時間を加算
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
            #親チケットは除外
            next unless issue.leaf?
            if issue.closed?
                close_date = issue.closed_on.to_date
                temp_ev[close_date].nil? ? temp_ev[close_date] = issue.estimated_hours : temp_ev[close_date] += issue.estimated_hours.to_f
            else
              #進捗率は入力されていたら出来高計算
              if issue.done_ratio > 0
                if @basis_date < issue.start_date
                  #開始日前だったら見積もり工数*進捗率を今日日付で計上
                  temp_ev[@basis_date] = (issue.estimated_hours * (issue.done_ratio / 100.0)).to_f
                else
                  #一日当たりの時間
                  hours_per_day = issue_hours_per_day(issue.estimated_hours ,issue.due_date, issue.start_date) * (issue.done_ratio / 100.0)
                  #チケットの期間の日毎に一日当たりの時間を加算
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
        #今日以降のEVは削除
        calculate_earned_value.delete_if{|key, value| key > @basis_date }
      end

      def calculate_actual_cost costs
        temp_ac = {}
        temp_ac = Hash[costs]
        # Sort and sum value
        calculate_actual_cost = sort_and_sum_evm_hash(temp_ac)
      end

      #チャート用データの加工
      def convert_to_chart hash_with_data 
        hash_converted = Hash[hash_with_data.map{ |k, v| [k.to_time(:utc).to_i * 1000, v] }]
        hash_converted.to_a
      end

      #
      def sort_and_sum_evm_hash evm_hash 
        temp_hash = {}
        sum_value = 0.0
        #
        if evm_hash.nil? || evm_hash[@basis_date].nil? || @basis_date <= evm_hash.keys.max
          evm_hash[@basis_date] = 0.0
        end        
        #累計を算出しながら日付順にソート
        evm_hash.sort_by{|key,val| key}.each do |date , value|
          sum_value += value
          temp_hash[date] = sum_value
        end        
        temp_hash
      end
    
      #一日当たりの見積もり時間を算出
      def issue_hours_per_day estimated_hours, due_date, start_date
        (estimated_hours / ((due_date + 1) - start_date)).to_f
      end

      #
      def chrat_minimum_date
        [@pv.keys.min, @ev.keys.min, @ac.keys.min].min
      end

      #
      def chrat_maximum_date
        [@pv.keys.max, @ev.keys.max, @ac.keys.max, forecast_finish_date].max
      end

      def forecast_finish_date
        @pv.keys.max + @pv.reject{|key, value| key <= @basis_date }.size * today_spi(8) 
      end

  end

end
