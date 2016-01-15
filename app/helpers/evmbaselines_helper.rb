# evm baseline helper
module EvmbaselinesHelper
  # Get local date time
  #
  # @param [datetime] bldatetime updated or created datetime
  # @return [String] formatted date
  def local_date(bldatetime)
    bldatetime.localtime.strftime('%Y-%m-%d %H:%M:%S') if bldatetime.present?
  end
end
