# Calculation EVM module
module CalculateEvmLogic

  # Calculation PV class.
  class CalculatePv
    # Constractor
    #
    # @param [date] basis_date basis date.
    # @param [issue] issues for culculation of PV.
    def initialize(basis_date, issues)
      # basis date
      @basis_date = basis_date
      # daily PV
      @daily_pv = calculate_planed_value issues
      # planed start date
      @start_date = @daily_pv.keys.min
      # planed due date
      @due_date = @daily_pv.keys.max
      # overdue?
      @overdue = @basis_date > @daily_pv.keys.max 
      # basis date
      @daily_pv[@basis_date] ||= 0.0
      # addup PV
      @cumulative_pv = sort_and_sum_evm_hash @daily_pv
    end

    # Badget at completion.=
    # Total estimate hours of issues.
    #
    # @return [Numeric] BAC
    def bac
      @cumulative_pv.values.max
    end

    # Today's planed value
    #
    # @return [Numeric] PV on basis date or PV of baseline.
    def today_value
      @cumulative_pv[@basis_date]
    end

    private
      # Calculate PV.
      # if due date is nil , set varsion due date.
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
      # Sort key value. key value is DATE.
      # Assending date.
      #
      # @param [hash] evm_hash target issues of EVM
      # @return [hash] Sorted EVM hash. Key:time, Value:EVM value
      def sort_and_sum_evm_hash(evm_hash)
        temp_hash = {}
        sum_value = 0.0
        evm_hash.sort_by {|key, _val| key }.each do |date, value|
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
        working_days = if @holiday_exclude
                         working_days = issue_days.reject {|e| e.wday == 0 || e.wday == 6 || e.holiday?(@holiday_region) }
                         working_days.length.zero? ? issue_days : working_days
                       else
                         issue_days
                       end
      end
  end
end
