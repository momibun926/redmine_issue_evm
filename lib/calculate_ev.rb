require "base_calculate"

# Calculation EVM module
module CalculateEvmLogic
  # Calculation EV class.
  # EV calculate estimate time of finished issue
  #
  class CalculateEv < BaseCalculateEvm
    # min date of spent time (exclude basis date)
    attr_reader :min_date
    # max date of spent time (exclude basis date)
    attr_reader :max_date
    # daily EV
    attr_reader :daily_ev
    # cumulative EV by date
    attr_reader :cumulative_ev
    # satate
    # progress: task is progress, finished: task is all completed.
    attr_reader :state

    # Constractor
    #
    # @param [date] basis_date basis date.
    # @param [issue] issues culculation of EV.
    def initialize(basis_date, issues)
      # basis date
      @basis_date = basis_date
      # daily EV
      @daily_ev = calculate_earned_value issues, basis_date
      # minimum start date
      # if no data, set basis date
      @min_date = @daily_ev.keys.min || @basis_date
      # maximum due date
      # if no data, set basis date
      @max_date = @daily_ev.keys.max || @basis_date
      # check state
      @state = check_state
      # basis date
      @daily_ev[@basis_date] ||= 0.0
      # addup EV
      @cumulative_ev = sort_and_sum_evm_hash @daily_ev
    end

    # Today"s earned value
    #
    # @return [Numeric] EV value on basis date
    def today_value
      @cumulative_ev[@basis_date]
    end

    private

    # Calculate EV.
    # Closed date or Date of ratio was set.
    #
    # @param [issue] issues target issues of EVM
    # @param [date] basis_date basis date of option
    # @return [hash] EV hash. Key:Date, Value:EV of each days
    def calculate_earned_value(issues, basis_date)
      temp_ev = {}
      @finished_issue_count = 0
      @issue_count = 0
      unless issues.nil?
        issues.each do |issue|
          # closed issue
          if issue.closed?
            closed_date = issue.closed_on || issue.updated_on
            dt = closed_date.to_time.to_date
            temp_ev[dt] += issue.estimated_hours.to_f unless temp_ev[dt].nil?
            temp_ev[dt] ||= issue.estimated_hours.to_f
            @finished_issue_count += 1
          # progress issue
          elsif issue.done_ratio.positive?
            hours = issue.estimated_hours.to_f * issue.done_ratio / 100.0
            # latest date of changed ratio
            ratio_date_utc = Journal.where(journalized_id: issue.id,
                                           journal_details: { prop_key: "done_ratio" }).
                                     joins(:details).
                                     maximum(:created_on)
            # parent isssue is no journals
            ratio_date = ratio_date_utc.to_time.to_date unless ratio_date_utc.nil?
            ratio_date ||= basis_date
            temp_ev[ratio_date] += hours unless temp_ev[ratio_date].nil?
            temp_ev[ratio_date] ||= hours
          end
          @issue_count += 1
        end
      end
      temp_ev
    end

    # state on basis date
    #
    # @return [String] state of plan on basis date
    def check_state
      @state = if @finished_issue_count < @issue_count
                 :progress
               elsif @issue_count == 0
                 :no_work
               elsif @finished_issue_count == @issue_count
                 :finished
               else
                 :NA
               end
    end
  end
end
