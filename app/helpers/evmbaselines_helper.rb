# evm baseline helper
module EvmbaselinesHelper
  # Get local date time
  #
  # @param [datetime] baseline_datetime updated or created datetime
  # @return [String] formatted date
  def local_date(baseline_datetime)
    baseline_datetime.localtime.strftime('%Y-%m-%d %H:%M:%S') if baseline_datetime.present?
  end
end
