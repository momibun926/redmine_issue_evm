module EvmLogic

  def actual_pv project_id
    issue_pv = {}
    #開始日と期日が入っているチケットが対象
    issues = @project.issues.where( "project_id = ? AND start_date IS NOT NULL AND due_date IS NOT NULL" , project_id )
    #チケットごとに以下を繰り返す
    issues.each do |issue|
      #親チケットは除外
      next unless issue.leaf?
      #一日当たりの時間
      per_hours_day = issue.estimated_hours / ((issue.due_date + 1) - issue.start_date)
      #チケットの期間の日毎に一日当たりの時間を加算
      (issue.start_date..issue.due_date).each do |key|
        if issue_pv[key].nil?
          issue_pv[key] = issue.estimated_hours
        else
          issue_pv[key] += issue.estimated_hours
        end
      end
    end
    #日付の若い順からPVを積み上げる
    actual_pv = {}
    sum_pv = 0
    issue_pv.sort_by{|key,val| key}.each do |date , pv|
      sum_pv += pv
      actual_pv[date] = sum_pv
    end
    actual_pv
  end

  def convert_to_chart(hash_with_data)
    #flot.js uses milliseconds in the date axis.
    hash_converted = Hash[hash_with_data.map{ |k, v| [k.to_time(:utc).to_i * 1000, v] }]
    #flot.js consumes arrays.
    hash_converted.to_a
  end

end