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

  # Constractor
  #
  # @param [Date] basis_date basis date.
  def initialize(basis_date)
    # basis date
    @basis_date = basis_date
  end

  # Cumulative ac at target date
  #
  # @param [Date] target_date pv at target date
  # @return [Hash] cumulative at ac target date
  def cumulative_at(target_date)
    @cumulative.select { |k, _v| k <= target_date }
  end

  private

  # Sort evm hash, Assending date.
  #
  # @param [Hash] evm_hash target issues of EVM
  # @return [Hash] Sorted EVM hash. Key:date, Value:EVM value
  def create_cumulative_evm(evm_hash)
    temp_hash = {}
    sum_value = 0.0
    evm_hash.sort_by { |key, _val| key }.each do |date, value|
      sum_value += value
      temp_hash[date] = sum_value
    end
    temp_hash
  end

  # Add daily EVM value
  #
  # @param [Numeric] evm_value EVM value
  # @param [Numeric] value EVM value
  # @param [Numeric] done_ratio done ratio
  # @return [Numeric] after add value
  def add_daily_evm_value(evm_value, value, done_ratio = 100)
    add_value = value.to_f * done_ratio.fdiv(100)
    evm_value.nil? ? add_value : evm_value.to_f + add_value
  end
end
