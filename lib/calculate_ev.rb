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
      # addup EV
      @cumulative = sort_and_sum_evm_hash @daily
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
    # Closed date or Date of ratio was set.
    #
    # @param [issue] issues target issues of EVM
    # @param [date] basis_date basis date of option
    # @return [hash] EV hash. Key:Date, Value:EV of each days
    def calculate_earned_value(issues, basis_date)
      temp_ev = {}
      @finished_issue_count = 0
      @issue_count = 0
      Array(issues).each do |issue|
        # closed issue
        if issue.closed?
          dt = (issue.closed_on || issue.updated_on).to_time.to_date
          temp_ev[dt] = add_hash_value temp_ev[dt], issue.estimated_hours.to_f
          @finished_issue_count += 1
        # progress issue
        elsif issue.done_ratio.positive?
          # latest date of changed ratio
          journals = Journal.where(journalized_id: issue.id, journal_details: { prop_key: "done_ratio" }).
                       where("created_on <= ?", basis_date.end_of_day).
                       joins(:details).
                       order(created_on: :DESC).first
          # calculate done hours
          if journals.present?
            dt = journals.created_on.to_time.to_date
            hours = issue.estimated_hours.to_f * journals.details.first.value.to_i / 100.0
            temp_ev[dt] = add_hash_value temp_ev[dt], hours
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
      return :no_work if @issue_count.zero?

      return :finished if calc_pv.present? && calc_pv.bac <= @cumulative[@basis_date]

      return :finished if @finished_issue_count == @issue_count

      :progress
    end
  end
end
