require "base_calculate"

# Calculation EVM module
module CalculateEvmLogic
  # Calculation PV class.
  # PV calculate estimate hours of issues.
  #
  class CalculatePv < BaseCalculateEvm
    # start date (exclude basis date)
    attr_reader :start_date
    # due date (exclude basis date)
    attr_reader :due_date
    # daily PV
    attr_reader :daily_pv
    # cumulative PV by date
    attr_reader :cumulative_pv
    # state on basis date
    # overdue: basis date is overdue, before_plan: basis date is before start date
    attr_reader :state

    # Constractor
    #
    # @param [date] basis_date basis date.
    # @param [issue] issues for culculation of PV.
    # @param [string] region setting region use calculation working days.
    def initialize(basis_date, issues, region)
      # basis date
      @basis_date = basis_date
      # region
      @region = region
      # daily PV
      @daily_pv = calculate_planed_value issues
      # planed start date
      @start_date = @daily_pv.keys.min || @basis_date
      # planed due date
      @due_date = @daily_pv.keys.max || @basis_date
      # state
      @state = check_state
      # basis date
      @daily_pv[@basis_date] ||= 0.0
      # addup PV
      @cumulative_pv = sort_and_sum_evm_hash @daily_pv
    end

    # Badget at completion
    # Total estimate hours of issues.
    #
    # @return [Numeric] BAC
    def bac
      @cumulative_pv.values.max
    end

    # Today"s planed value
    #
    # @return [Numeric] PV on basis date or PV of baseline.
    def today_value
      @cumulative_pv[@basis_date]
    end

    private

    # Calculate PV.
    # if due date is nil , set varsion due date.
    #
    # @note If the due date has not been entered, we will use the due date of the version
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
      adjusted_days = if @holiday_exclude
                        working_days = issue_days.reject { |e| e.wday == 0 || e.wday == 6 || e.holiday?(@region) }
                        working_days.length.zero? ? issue_days : working_days
                      else
                        issue_days
                      end
    end

    # state on basis date
    #
    # @return [String] state of plan on basis date
    def check_state
      @state = if @due_date < @basis_date
                 :overdue
               elsif @basis_date < @start_date
                 :before_plan
               else
                 :working
               end
    end
  end
end
