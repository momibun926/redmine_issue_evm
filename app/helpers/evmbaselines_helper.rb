module EvmbaselinesHelper

  def local_date baseline_datetime
    baseline_datetime.localtime.strftime("%Y-%m-%d %H:%M:%S") if baseline_datetime.present?
  end

end
