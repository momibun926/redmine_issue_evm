class EvmBaseline < ActiveRecord::Base
  unloadable
  has_many :evm_baseline_issues, dependent: :destroy
end
