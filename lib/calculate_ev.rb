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
  # @param [Date] basis_date basis date.
  # @param [Issue] issues culculation of EV.
  def initialize(basis_date, issues)
    super(basis_date)
    # daily EV
    @daily = calculate_earned_value(issues, @basis_date)
    # minimum start date
    # if no data, set basis date
    @min_date = @daily.keys.min || @basis_date
    # maximum due date
    # if no data, set basis date
    @max_date = @daily.keys.max || @basis_date
    # basis date
    @daily[@basis_date] ||= 0.0
    # cumulative EV
    @cumulative = create_cumulative_evm(@daily)
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
  # @param [Issue] issues target issues of EVM
  # @param [Date] basis_date basis date of option
  # @return [Hash] EV hash. Key:Date, Value:EV of each days
  def calculate_earned_value(issues, basis_date)
    temp_ev = {}
    @finished_issue_count = 0
    @issue_count = 0
    Array(issues).each do |issue|
      # 1.closed issue
      if issue.closed?
        closed_dt = User.current.time_to_date(issue.closed_on)
        temp_ev = create_ev_from_journals(issue,
                                          basis_date,
                                          temp_ev,
                                          closed_dt)
        @finished_issue_count += 1
      # 2.progless issue (setted done ratio)
      elsif issue.done_ratio.positive?
        temp_ev = create_ev_from_journals(issue,
                                          basis_date,
                                          temp_ev)
      # 3.parent issue of children is progress or closed
      elsif issue.children?
        child = issue_child(issue)
        if child.closed_on.present?
          dt = User.current.time_to_date(child.closed_on)
          temp_ev[dt] = add_daily_evm_value(temp_ev[dt],
                                            issue.estimated_hours.to_f,
                                            issue.done_ratio)
        end
      end
      @issue_count += 1
    end
    temp_ev
  end

  # create ev value from Ratio of journals
  #
  # @param [Issue] issue target issue record
  # @param [Date] basis_date basis date
  # @param [Hash] ev_hash EV hash
  # @param [datetime] closed_dt closed datetime of issue
  # @return [Hash] rartio in jouranals
  def create_ev_from_journals(issue, basis_date, ev_hash, closed_dt = nil)
    temp_ev = ev_hash
    journals = issue_journal(issue, basis_date)
    if journals.present? || closed_dt.present?
      # Create date and ratio of journals
      daily_ratio = daily_done_ratio(journals, closed_dt)
      # create EV from ratio
      temp_ev = create_ev_from_ratio(issue.estimated_hours.to_f, temp_ev, daily_ratio)
    end
    temp_ev
  end

  # Ratio of journals
  #
  # @param [journal] jnls journals of issue
  # @param [datetime] closed_dt closed datetime of issue
  # @return [Hash] rartio in jouranals
  def daily_done_ratio(jnls, closed_dt = nil)
    ratio_hash = {}
    jnls.each do |jnl|
      ratio_hash[User.current.time_to_date(jnl.created_on)] = jnl.details.first.value.to_i
    end
    # when closed date exist, ratio=100
    ratio_hash[closed_dt] = 100 unless closed_dt.nil?
    ratio_hash
  end

  # Create ev from ratio
  #
  # @param [float] estimae_hrs estimate hours of issue
  # @param [Hash] ev_hash EV
  # @param [Hash] ratio_date_hash ration each day
  # @return [Hash] EV hash
  def create_ev_from_ratio(estimae_hrs, ev_hash, ratio_date_hash)
    temp = ev_hash
    before_ratio = 0
    ratio_date_hash.each do |k, v|
      ratio_dif = v - before_ratio
      temp[k] = add_daily_evm_value(temp[k],
                                    estimae_hrs,
                                    ratio_dif)
      before_ratio = v
    end
    temp
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
