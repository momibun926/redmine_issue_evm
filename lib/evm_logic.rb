module EvmLogic

  def actual_issue_pv project_id
    temp_pv = {}
    #開始日と期日が入っているチケットが対象
    issues = @project.issues.where( "start_date IS NOT NULL AND due_date IS NOT NULL" , project_id )
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
    # Sort by key
    actual_pv = sort_evm_hash(temp_pv)
  end

  def issue_ev project_id
    temp_ev = {}
    #開始日と期日が入っているチケットが対象
    issues = @project.issues.where( "start_date IS NOT NULL AND due_date IS NOT NULL" , project_id )
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
          if Time.now.to_date < issue.start_date
            #開始日前だったら見積もり工数*進捗率を今日日付で計上
            temp_ev[Time.now.to_date] = issue.estimated_hours * (issue.done_ratio / 100.0)
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
    # Sort by key
    issue_ev = sort_evm_hash(temp_ev)
    #今日以降のEVは削除
    issue_ev.delete_if{|key, value| key > Time.now.to_date }
  end

  def issue_ac project_id
    temp_ac = {}
    query = @project.issues.select('MAX(spent_on) AS spent_on, SUM(hours) AS sum_hours').
            joins(:time_entries).
            group('spent_on').collect { |issue| [issue.spent_on, issue.sum_hours] }
    temp_ac = Hash[query]
    #　sort by key
    issue_ac = sort_evm_hash(temp_ac)
  end

  def bac issue_pv_hash, hours
    bac = issue_pv_hash[issue_pv_hash.keys.max] / hours
    bac.round(2)
  end

  def complete_ev issue_ev_hash, issue_pv_hash
    complete_ev = today_ev(issue_ev_hash, 1) / bac(issue_pv_hash, 1)
    complete_ev.round(2)
  end

  def today_pv issue_pv_hash, hours
    pv = issue_pv_hash[Time.now.to_date] / hours
    pv.round(2)
  end

  def today_ev issue_ev_hash, hours
    ev = issue_ev_hash[Time.now.to_date] / hours
    ev.round(2)
  end
  
  def today_ac issue_ac_hash, hours
    ac = issue_ac_hash[Time.now.to_date] / hours
    ac.round(2)
  end

  def today_sv ev, pv
    sv = (ev - pv)
    sv.round(2)
  end

  def today_cv ev, ac
    cv = (ev - ac)
    cv.round(2)
  end

  def today_spi ev, pv
    spi = ev / pv
    spi.round(2)
  end

  def today_cpi ev, ac
    cpi = ev / ac
    cpi.round(2)
  end

  def today_cr ev, ac, pv
    cr = today_spi(ev, pv) * today_cpi(ev, ac)
    cr.round(2)
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
    if evm_hash[Time.now.to_date].nil?
      evm_hash[Time.now.to_date] = 0
    end
    evm_hash.sort_by{|key,val| key}.each do |date , value|
      sum_value += value
      temp_hash[date] = sum_value
    end
    #今日が最大日を超えていたら、今日に最大値をセット
    if temp_hash.keys.max < Time.now.to_date
      temp_hash[Time.now.to_date] = temp_hash[temp_hash.keys.max]
    end
    temp_hash
  end
  
  #一日当たりの見積もり時間を算出
  def issue_hours_per_day estimated_hours, due_date, start_date
    estimated_hours / ((due_date + 1) - start_date)
  end

end
