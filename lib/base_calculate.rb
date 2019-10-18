# Calculation EVM module
module CalculateEvmLogic
  # Calculation EVM base class.
  # This class is base class of calculate AC, EV, PV(issues, baseline)
  #
  class BaseCalculateEvm
    # Basis date
    attr_reader :basis_date

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
