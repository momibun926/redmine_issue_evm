module CalculateEvmLogic
  # Export of the PV, EV and AC of each date as CSV.
  # Mixed into CalculateEvmLogic::CalculateEvm, whose instance variables the methods use.
  module CsvExport
    # Create data for csv export.
    #
    # @return [Hash] csv data
    def to_csv
      Redmine::Export::CSV.generate do |csv|
        # date range
        evm_date_range = csv_date_range
        # title
        csv << ["DATE", *evm_date_range]
        # evm values each date
        csv << ["PV", *csv_cumulative_values(@pv, evm_date_range)]
        csv << ["EV", *csv_cumulative_values(@ev, evm_date_range)]
        csv << ["AC", *csv_cumulative_values(@ac, evm_date_range)]
      end
    end

    private

    # Dates of csv export, from the first to the last date of PV, EV and AC.
    #
    # @return [Array] dates
    def csv_date_range
      csv_min_date = [@ev.min_date, @ac.min_date, @pv.start_date].min
      csv_max_date = [@ev.max_date, @ac.max_date, @pv.due_date].max
      (csv_min_date..csv_max_date).to_a
    end

    # Cumulative values of each date for csv export.
    #
    # @param [BaseCalculateEvm] calc_evm PV, EV or AC
    # @param [Array] dates dates of csv
    # @return [Array] cumulative value of each date, rounded. nil is no value on the date.
    def csv_cumulative_values(calc_evm, dates)
      dates.map { |csv_date| calc_evm.cumulative[csv_date]&.round(2) }
    end
  end
end
