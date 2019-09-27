# Calculation EVM module
module EvmLogic

  # Calculation EV class.
  class CalculateEv
    # Constractor
    #
    # @param [issue] issues culculation of EV.
    # @param [date] basis_date basis date.
    def initialize(issues, basis_date)
      # basis date
      @basis_date = basis_date
      # minimum start date
      @min_date = issues.minimum(:start_date)
      # maximum due date
      @max_date = issues.maximum(:due_date)
      # daily EV
      @daily_ev = calculate_earned_value issues, basis_date
      # addup EV
      @addup_ev = sort_and_sum_evm_hash @daily_ev
      # finished
      @finished = false
    end
    
    # Today earned value
    # EV by the specified date.
    #
    # @return [Numeric] EV on basis date
    def today_value
      ev = @addup_ev(@basis_date)
      ev.round(1)
    end

    # Task is finished?
    #
    # @return [bool] task is finished?
    def finished
      @finished
    end

    private

      # Calculate EV.
      # Closed date or Date of ratio was set.
      #
      # @param [issue] issues target issues of EVM
      # @param [basis_date] basis date of option
      # @return [hash] EV hash. Key:Date, Value:EV of each days
      def calculate_earned_value(issues, basis_date)
        ev = {}
        unfinished = false
        unless issues.nil?
          issues.each do |issue|
            # closed issue
            if issue.closed?
              closed_date = issue.closed_on || issue.updated_on
              dt = closed_date.to_time.to_date
              ev[dt] += issue.estimated_hours.to_f unless ev[dt].nil?
              ev[dt] ||= issue.estimated_hours.to_f
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
              ev[ratio_date] += hours unless ev[ratio_date].nil?
              ev[ratio_date] ||= hours
              unfinished = true
            else
              unfinished = true
            end
          end
        end
        # all issue is finisshed?
        @finished = issues.present? && !unfinished
        # set basis date value
        ev[@basis_date] ||= 0.0
      end

      # Sort key value. key value is DATE.
      # Assending date.
      #
      # @param [hash] evm_hash target issues of EVM
      # @return [hash] Sorted EVM hash. Key:time, Value:EVM value
      def sort_and_sum_evm_hash(evm_hash)
        temp_hash = {}
        if evm_hash.blank?
          evm_hash[@basis_date] ||= 0.0
        end
        sum_value = 0.0
        evm_hash.sort_by {|key, _val| key }.each do |date, value|
          sum_value += value
          temp_hash[date] = sum_value
        end
        temp_hash
      end
  end
end
