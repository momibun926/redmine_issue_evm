module EvmLogic

  class IssueEvm

    def initialize baselines, issues, costs, basis_date, forecast, etc_method
      #基準日
      @@basis_date = basis_date
      #予測値の表示
      @@forecast = forecast
      #ETCの計算方法
      @@etc_method = etc_method
      #チケットのPV(日付:値)
      @@actual_pv = issue_pv issues
      @@actual_pv[@@basis_date] = 0.0 if @@actual_pv.nil?
      #ベースラインのPV(日付:値)
      @@baseline_pv = issue_pv baselines
      @@baseline_pv[@@basis_date] = 0.0 if @@baseline_pv.nil?
      #チケットのEV(日付:値)
      @@issue_ev = issue_ev issues
      @@issue_ev[@@basis_date] = 0.0 if @@issue_ev.nil?
      #チケットのAC(日付:値)
      @@issue_ac = issue_ac costs
      @@issue_ac[@@basis_date] = 0.0 if @@issue_ac.nil?
    end

    #基準日
    def basis_date
      @@basis_date
    end

    #BAC
    #予定総工数
    def bac hours
      bac = @@actual_pv[@@actual_pv.keys.max] / hours
      bac.round(2)
    end

    #CompleteEV
    #BACに対する出来高完了率
    def complete_ev hours
      complete_ev = today_ev(hours) / bac(hours)
      complete_ev.nan? ? 0 : complete_ev.round(2)
    end
    
    #PV
    #基準日時点のPV
    def today_pv hours
      pv = @@actual_pv[@@basis_date] / hours
      pv.round(2)
    end

    #EV
    #基準日時点のEV
    def today_ev hours
      ev = @@issue_ev[@@basis_date] / hours
      ev.round(2)
    end
    
    #AC
    #基準日時点のAC
    def today_ac hours
      ac = @@issue_ac[@@basis_date] / hours
      ac.round(2)
    end

    #SV
    #スケジュール差異(EV-PV)
    def today_sv hours
      sv = (today_ev(hours) - today_pv(hours))
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
      spi = today_ev(hours) / today_pv(hours)
      spi.nan? ? 0.0 : spi.round(2)
    end

    #CPI
    #コストパフォーマンス(EV/AC)
    def today_cpi hours
      cpi = today_ev(hours) / today_ac(hours)
      cpi.nan? ? 0.0 : cpi.round(2)
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
      if today_cpi(hours) == 0.0
        etc = 0.0  
      else
        case @@etc_method
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
      eac = eac.nan? ? 0.0 : eac.round(2)
    end

    #VAC
    #BAC－EAC
    def vac hours
      vac = bac(hours) - eac(hours)
      vac.round(2)
    end

    def delay
      unless forecast_finish_date.nil?
        (forecast_finish_date - @@actual_pv.keys.max).to_i
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

      chart_date['planned_value'] = convert_to_chart(@@actual_pv)
      chart_date['actual_cost'] = convert_to_chart(@@issue_ac)
      chart_date['earned_value'] = convert_to_chart(@@issue_ev)
      chart_date['baseline_value'] = convert_to_chart(@@baseline_pv)

      if @@forecast
        bac_top_line = {chrat_minimum_date => bac(1), chrat_maximum_date => bac(1)}
        chart_date['bac_top_line'] = convert_to_chart(bac_top_line)
        eac_top_line = {chrat_minimum_date => eac(1), chrat_maximum_date => eac(1)}
        chart_date['eac_top_line'] = convert_to_chart(eac_top_line)
        actual_cost_forecast = {@@basis_date => today_ac(1), forecast_finish_date => eac(1)}
        chart_date['actual_cost_forecast'] = convert_to_chart(actual_cost_forecast)
        earned_value_forecast = {@@basis_date => today_ev(1), forecast_finish_date => @@actual_pv[@@actual_pv.keys.max]}
        chart_date['earned_value_forecast'] = convert_to_chart(earned_value_forecast)
      end

      chart_date
    end

    private
      #チケットからPlanValueを計算
      #
      #
      def issue_pv issues
        temp_pv = {}
        #チケットごとに以下を繰り返す
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
        # Sort and sum value
        issue_pv = sort_evm_hash(temp_pv)
      end

      def issue_ev issues
        temp_ev = {}
        #チケットごとに以下を繰り返す
        issues.each do |issue|
          #親チケットは除外
          next unless issue.leaf?
          if issue.closed?
              close_date = issue.closed_on.to_date
              temp_ev[close_date].nil? ? temp_ev[close_date] = issue.estimated_hours : temp_ev[close_date] += issue.estimated_hours
          else
            #進捗率は入力されていたら出来高計算
            if issue.done_ratio > 0
              if @@basis_date < issue.start_date
                #開始日前だったら見積もり工数*進捗率を今日日付で計上
                temp_ev[@@basis_date] = issue.estimated_hours * (issue.done_ratio / 100.0)
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
        # Sort and sum value
        issue_ev = sort_evm_hash(temp_ev)
        #今日以降のEVは削除
        issue_ev.delete_if{|key, value| key > @@basis_date }
      end

      def issue_ac costs
        temp_ac = {}
        temp_ac = Hash[costs]
        # Sort and sum value
        issue_ac = sort_evm_hash(temp_ac)
      end

      #チャート用データの加工
      def convert_to_chart hash_with_data 
        hash_converted = Hash[hash_with_data.map{ |k, v| [k.to_time(:utc).to_i * 1000, v] }]
        hash_converted.to_a
      end

      #日付の若い順からEVを積み上げる
      def sort_evm_hash evm_hash 
        temp_hash = {}
        sum_value = 0
        #今日の値がなかったら0をセット
        if evm_hash[@@basis_date].nil?
          evm_hash[@@basis_date] = 0
        end
        evm_hash.sort_by{|key,val| key}.each do |date , value|
          sum_value += value
          temp_hash[date] = sum_value
        end
        #今日が最大日を超えていたら、今日に最大値をセット
        if temp_hash.keys.max < @@basis_date
          temp_hash[@@basis_date] = temp_hash[temp_hash.keys.max]
        end
        temp_hash
      end
    
      #一日当たりの見積もり時間を算出
      def issue_hours_per_day estimated_hours, due_date, start_date
        estimated_hours / ((due_date + 1) - start_date)
      end

      #
      def chrat_minimum_date
        [@@actual_pv.keys.min, @@issue_ev.keys.min, @@issue_ac.keys.min].min
      end

      #
      def chrat_maximum_date
        [@@actual_pv.keys.max, @@issue_ev.keys.max, @@issue_ac.keys.max, forecast_finish_date].max
      end

      def forecast_finish_date
        @@actual_pv.keys.max + @@actual_pv.reject{|key, value| key <= @@basis_date }.size * today_spi(8) 
      end

  end

end
