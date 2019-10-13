# Calculation EVM module
module CalculateEvmLogic

  # Calculation EVM class.
  # Spent time of target issues.
  class CalculateAc
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

    # Basis date
    attr_reader :basis_date

    # Today's Actual cost
    #
    # @return [Numeric] AC on basis date
    def today_ac
      @cumulative_ac[@basis_date]
    end

    private
      # Sort evm hash, Assending date.
      #
      # @param [hash] evm_hash target issues of EVM
      # @return [hash] Sorted EVM hash. Key:date, Value:EVM value
      def sort_and_sum_evm_hash(evm_hash)
        temp_hash = {}
        sum_value = 0.0
        evm_hash.sort_by {|key, _val| key }.each do |date, value|
          sum_value += value
          temp_hash[date] = sum_value
        end
        temp_hash
      end
  end
end
