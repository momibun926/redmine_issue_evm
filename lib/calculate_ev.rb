require "base_calculate"

# Calculation EVM module
module CalculateEvmLogic
  # Calculation EV class.
  # EV calculate estimate time of finished issue
  #
  class CalculateEv < BaseCalculateEvm
    include IssueDataFetcher
    # min date of spent time (exclude basis date)
    attr_reader :min_date
    # max date of spent time (exclude basis date)
    attr_reader :max_date

    # Constractor
    #
    # @param [date] basis_date basis date.
    # @param [issue] issues culculation of EV.
    def initialize(basis_date, issues)
      # basis date
      @basis_date = basis_date
      # daily EV
      @daily = calculate_earned_value issues, basis_date
      # minimum start date
      # if no data, set basis date
      @min_date = @daily.keys.min || @basis_date
      # maximum due date
      # if no data, set basis date
      @max_date = @daily.keys.max || @basis_date
      # basis date
      @daily[@basis_date] ||= 0.0
      # cumulative EV
      @cumulative = create_cumulative_evm @daily
      @cumulative.reject! { |k, _v| @basis_date < k }
    end

    # Today's earned value
    #
    # @return [Numeric] EV value on basis date
    def today_value
      @cumulative[@basis_date]
    end

    # State
    #
    # @param [CalculatePv] calc_pv CalculatePv object
    # @return [Numeric] EV value on basis date
    def state(calc_pv = nil)
      check_state(calc_pv)
    end

    private

    # Calculate EV.
    # 1.closed issue
    # 2.progless issue (setted done ratio)
    # 3.parent issue of children is progress or closed
    #
    # @param [issue] issues target issues of EVM
    # @param [date] basis_date basis date of option
    # @return [hash] EV hash. Key:Date, Value:EV of each days
    def calculate_earned_value(issues, basis_date)
      temp_ev = {}
      @finished_issue_count = 0
      @issue_count = 0
      Array(issues).each do |issue|
        # 1.closed issue
        if issue.closed?
          dt = issue.closed_on.in_time_zone.to_date
          temp_ev[dt] = add_daily_evm_value temp_ev[dt],
                                            issue.estimated_hours.to_f
          @finished_issue_count += 1
        # progress issue,
        elsif issue.done_ratio.positive?
          # 2.progless issue (setted done ratio)
          journals = issue_journal issue, basis_date
          if journals.present?
            dt = journals.created_on.in_time_zone.to_date
            temp_ev[dt] = add_daily_evm_value temp_ev[dt],
                                              issue.estimated_hours.to_f,
                                              journals.details.first.value.to_i
          # 3.parent issue of children is progress or closed
          elsif issue.children?
            child = issue_child issue
            if child.closed_on.present?
              dt = child.closed_on.in_time_zone.to_date
              temp_ev[dt] = add_daily_evm_value temp_ev[dt],
                                                issue.estimated_hours.to_f,
                                                issue.done_ratio
            end
          end
        end
        @issue_count += 1
      end
      temp_ev
    end

    # state on basis date
    #
    # @param [CalculatePv] calc_pv CalculatePv object
    # @return [String] state of project
    def check_state(calc_pv = nil)
      # no finished isshe
      return :no_work if @issue_count.zero?
      # bac <= basis date is finished
      return :finished if calc_pv.present? && calc_pv.bac <= @cumulative[@basis_date]
      # basis date is before max ev date(latest finished issue)
      return :progress if @basis_date < @max_date
      # all issue is finished
      return :finished if @finished_issue_count == @issue_count

      :progress
    end
  end
end
