# Calculation EVM module
module CalculateEvmLogic

  # Calculation AC class.
  # AC calculate Spent time of pv issues.
  # 
  class CalculateAc < BaseCalculateEvm
    # overdue?
    attr_reader :overdue
    # min date of spent time (exclude basis date)
    attr_reader :min_date
    # max date of spent time (exclude basis date)
    attr_reader :max_date
    # Constractor
    #
    # @param [date] basis_date basis date.
    # @param [costs] costs culculation of AC.
    def initialize(basis_date, costs)
      # basis date
      @basis_date = basis_date
      # daily AC
      @daily_ac = Hash[costs]
      # minimum first date
      @min_date = @daily_ac.keys.min
      # maximum last date
      @max_date = @daily_ac.keys.max
      # basis date
      @daily_ac[@basis_date] ||= 0.0
      # addup AC
      @cumulative_ac = sort_and_sum_evm_hash @daily_ac
    end
    # Today's Actual cost
    #
    # @return [Numeric] AC on basis date
    def today_ac
      @cumulative_ac[@basis_date]
    end
  end

end
