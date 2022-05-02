# Calculation AC class.
# AC calculate Spent time of pv issues.
#
class CalculateAc < BaseCalculateEvm
  # min date of spent time (exclude basis date)
  attr_reader :min_date
  # max date of spent time (exclude basis date)
  attr_reader :max_date

  # Constractor
  #
  # @param [Date] basis_date basis date.
  # @param [costs] costs culculation of AC.
  def initialize(basis_date, costs)
    super(basis_date)
    # daily AC
    @daily = costs.to_h
    # minimum first date
    # if no data, set basis date
    @min_date = @daily.keys.min || @basis_date
    # maximum last date
    # if no data, set basis date
    @max_date = @daily.keys.max || @basis_date
    # basis date
    @daily[@basis_date] ||= 0.0
    # cumulative AC
    @cumulative = create_cumulative_evm(@daily)
    @cumulative.reject! { |k, _v| @basis_date < k }
  end

  # Today's Actual cost
  #
  # @return [Numeric] AC on basis date
  def today_value
    @cumulative[@basis_date]
  end
end
