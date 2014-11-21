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
        if issue.done_ratio > 0
          #一日当たりの時間
          hours_per_day = issue_hours_per_day(issue.estimated_hours ,issue.due_date, issue.start_date) * (issue.done_ratio / 100)
        else
          #一日当たりの時間
          hours_per_day = issue_hours_per_day(issue.estimated_hours ,issue.due_date, issue.start_date)
        end
        #チケットの期間の日毎に一日当たりの時間を加算
        (issue.start_date..issue.due_date).each do |key|
          temp_ev[key].nil? ? temp_ev[key] = hours_per_day : temp_ev[key] += hours_per_day
        end
      end
    end
    issue_ev = sort_evm_hash(temp_ev)
  end

  def issue_ac project_id
    temp_ac = {}
    query = @project.issues.select('MAX(spent_on) AS spent_on, SUM(hours) AS sum_hours').
            joins(:time_entries).
            group('spent_on').collect { |issue| [issue.spent_on, issue.sum_hours] }
    temp_ac = Hash[query]
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
    evm_hash.sort_by{|key,val| key}.each do |date , value|
      sum_value += value
      temp_hash[date] = sum_value
    end
    temp_hash
  end

  def issue_hours_per_day estimated_hours, due_date, start_date
    estimated_hours / ((due_date + 1) - start_date)
  end

end