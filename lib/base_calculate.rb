# Calculation EVM module
module CalculateEvmLogic
  # Calculation EVM base class.
  # This class is base class of calculate AC, EV, PV(issues, baseline)
  #
  class BaseCalculateEvm
    # Basis date
    attr_reader :basis_date
    # daily element
    attr_reader :daily
    # cumulative by date
    attr_reader :cumulative

    # Cumulative ac at target date
    #
    # @param [date] target_date pv at target date
    # @return [hash] cumulative at ac target date
    def cumulative_at(target_date)
      @cumulative.select { |k, _v| k <= target_date }
    end

    private

    # Sort evm hash, Assending date.
    #
    # @param [hash] evm_hash target issues of EVM
    # @return [hash] Sorted EVM hash. Key:date, Value:EVM value
    def sort_and_sum_evm_hash(evm_hash)
      temp_hash = {}
      sum_value = 0.0
      evm_hash.sort_by { |key, _val| key }.each do |date, value|
        sum_value += value
        temp_hash[date] = sum_value
      end
      temp_hash
    end

    # Add hash value
    #
    # @param [hash] evm_hash EVM hash
    # @param [numeric] value EVM value
    # @return [numeric] after add value
    def add_hash_value(evm_hash, value)
      evm_hash.present? ? evm_hash + value : value
    end
  end
end
