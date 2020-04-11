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
    # state on basis date
    # overdue: basis date is overdue, before_plan: basis date is before start date
    attr_reader :state
    # Rest days
    attr_reader :rest_days

    # Constractor
    #
    # @param [date] basis_date basis date.
    # @param [issue] issues for culculation of PV.
    # @param [string] region setting region use calculation working days.
    # @param [string] exclude_holiday setting exclude holiday
    def initialize(basis_date, issues, region, exclude_holiday)
      # basis date
      @basis_date = basis_date
      # region
      @region = region
      # exclude holiday
      @holiday_exclude = exclude_holiday
      # daily PV
      @daily = calculate_planed_value issues
      # planed start date
      @start_date = @daily.keys.min || @basis_date
      # planed due date
      @due_date = @daily.keys.max || @basis_date
      # state
      @state = check_state
      # basis date
      @daily[@basis_date] ||= 0.0
      # cumulative PV
      @cumulative = create_cumulative_evm @daily
      # Rest days
      @rest_days = @basis_date > @due_date ? 0 : amount_working_days(@basis_date, @due_date)
    end

    # Badget at completion (BAC)
    # Total estimate hours of issues.
    #
    # @return [Numeric] BAC
    def bac
      @cumulative.values.max
    end

    # Schadule at completion.
    # This is the original planned completion duration (days) of the project.
    #
    # @return [Numeric] SAC (days)
    def sac
      amount_working_days(start_date, due_date)
    end

    # Today"s planed value
    #
    # @return [Numeric] PV on basis date or PV of baseline.
    def today_value
      @cumulative[@basis_date]
    end

    # Actual Time (AT)
    # This is the duration from the beginning of the project to basis date.
    #
    # @param [date] status_date project finished date or basis date.
    # @return [Numeric] days: basis date - start date
    def today_at(status_date)
      amount_working_days(@start_date, status_date)
    end

    # Earned schedule (ES)
    # This duration from the beginning of the project to the date
    # on which the PV should have been equal to the current value of EV.
    #
    # @param [numeric] ev_value EV value of basis date.
    # @return [date] earned shedule
    def today_es(ev_value)
      return 0 if @state == :before_plan

      es_date_pv = if @state == :overdue
                     @cumulative.select { |k, _v| (k < @basis_date) }
                   else
                     @cumulative
                   end
      es_date = es_date_pv.select { |_k, v| (v <= ev_value) }.keys.max
      es_date.nil? ? 0 : amount_working_days(@start_date, es_date)
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
      Array(issues).each do |issue|
        issue.due_date ||= Version.find(issue.fixed_version_id).effective_date
        pv_days = working_days issue.start_date, issue.due_date
        hours_per_day = issue_hours_per_day issue.estimated_hours.to_f, pv_days.length
        pv_days.each do |date|
          temp_pv[date] = add_daily_evm_value temp_pv[date], hours_per_day
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
    # exclude weekends and holiday or include weekends and holiday.
    #
    # @param [date] start_date start date of issue
    # @param [date] end_date end date of issue
    # @return [Array] working days
    def working_days(start_date, end_date)
      issue_days = (start_date..end_date).to_a
      if @holiday_exclude
        working_days = issue_days.reject { |e| e.wday.zero? || e.wday == 6 || e.holiday?(@region) }
        working_days.length.zero? ? issue_days : working_days
      else
        issue_days
      end
    end

    # Amount of working days.
    #
    # @param [date] start_date start date
    # @param [date] end_date end date
    # @return [Numeric] Amount of working days
    def amount_working_days(start_date, end_date)
      working_days(start_date, end_date).length
    end

    # state on basis date
    #
    # @return [String] state of plan on basis date
    def check_state
      if @due_date < @basis_date
        :overdue
      elsif @basis_date < @start_date
        :before_plan
      else
        :within_duration
      end
    end
  end
end
